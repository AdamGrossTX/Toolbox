[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')       | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\System.Windows.Interactivity.dll') | out-null

########################################################################################################################################################################################################	
#*******************************************************************************************************************************************************************************************************
#																						 PROGRESSBAR DESIGN 
#*******************************************************************************************************************************************************************************************************
########################################################################################################################################################################################################
$syncProgress = [hashtable]::Synchronized(@{})
$childRunspace =[runspacefactory]::CreateRunspace()
$childRunspace.ApartmentState = "STA"
$childRunspace.ThreadOptions = "ReuseThread"         
$childRunspace.Open()
$childRunspace.SessionStateProxy.SetVariable("syncProgress",$syncProgress)          
$PsChildCmd = [PowerShell]::Create().AddScript({   
    [xml]$xaml = @"
	<Controls:MetroWindow 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		xmlns:i="http://schemas.microsoft.com/expression/2010/interactivity"				
		xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"		
        x:Name="WindowProgress" 
		WindowStyle="None" 
		WindowStartupLocation = "CenterScreen"  
		AllowsTransparency="True" 
		WindowState="Maximized"		
		UseNoneWindowStyle="True"	
		>

	<Window.Resources>
		<ResourceDictionary>
			<ResourceDictionary.MergedDictionaries>
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Controls.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Fonts.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Colors.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/Cobalt.xaml" />
				<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/BaseLight.xaml" />
			</ResourceDictionary.MergedDictionaries>
		</ResourceDictionary>
	</Window.Resources>		

	<Window.Background>
		<SolidColorBrush Opacity="0.7" Color="#0077D6"/>
	</Window.Background>	
		
	<Grid HorizontalAlignment="Center" VerticalAlignment="Center">	
		<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,15,0,0">	
			<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,0,0,0">	
				<Controls:ProgressRing x:Name="Deployment_Progressbar" IsActive="True" Margin="0,0,0,0"  Foreground="White" Width="50"/>
			</StackPanel>								
			
			<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,0,0,0">				
				<Label Content="Your computer is being installed" FontSize="17" Margin="0,0,0,0" Foreground="White"/>	
			</StackPanel>	
		
			<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,0,0,0">							
				<Label x:Name="Step_Status" Margin="0,0,0,0" FontSize="17"  Foreground="White"/>		
				<Label x:Name="Progress_Status"  FontSize="17" Margin="0,5,0,0" Foreground="White" HorizontalAlignment="Center"/>
			</StackPanel>	
		</StackPanel>										
	</Grid>
</Controls:MetroWindow>
"@
  
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $syncProgress.Window=[Windows.Markup.XamlReader]::Load( $reader )
    $syncProgress.ProgressRing = $syncProgress.window.FindName("Deployment_Progressbar")
    $syncProgress.Label2 = $syncProgress.window.FindName("Step_Status")
    $syncProgress.Label = $syncProgress.window.FindName("Progress_Status")

    $syncProgress.Window.ShowDialog() | Out-Null
    $syncProgress.Error = $Error
})


#########################################################################################################################################################################################################	
#*******************************************************************************************************************************************************************************************************
#																			FUNCTIONS
#*******************************************************************************************************************************************************************************************************
#########################################################################################################################################################################################################	

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$Global:Total_Step = $tsenv.Value("_SMSTSInstructionTableSize")

################ Launch Progress Bar  ########################  
Function Launch_modal_progress{    
    #lanunch the modal window with the progressbar
    $PsChildCmd.Runspace = $childRunspace
    $Script:Childproc = $PsChildCmd.BeginInvoke()
}

################ Update Progress Bar  ########################  
Function Update_progressBar {
    param(
    [String]$script:Step_Name,
    [String]$script:Step_Status		
    )
    $syncProgress.ProgressRing.Dispatcher.Invoke("Normal",[action]{
        $syncProgress.Label.Content=$script:Step_Name
        $syncProgress.Label2.Content=$script:Step_Status			
    })
}

################ Close Progress Bar  ########################  
Function Close_modal_progress{
    $syncProgress.Window.Dispatcher.Invoke([action]{$syncProgress.Window.close()})
    $PsChildCmd.EndInvoke($Script:Childproc) | Out-Null
    $childRunspace.Close() | Out-Null 
}

$Previous_Step = " " 
Launch_modal_progress
Sleep 3

$TSProgressUI = New-object -comobject Microsoft.SMS.TSProgressUI

Do
	{			
		$Current_Step_Number = $tsenv.Value("_SMSTSNextInstructionPointer")
		$Current_Step_Name = $tsenv.Value("_SMSTSCurrentActionName")
		$Next_Step = $tsenv.Value("_SMSTSCurrentActionName")		

		If ($Previous_Step -ne $Next_Step)
			{
				$Current_Step_Total = $Current_Step_Number / $Total_Step * 100 
				$Round_Current_Step_Total = [math]::Round($Current_Step_Total)
				$Percent_Complete = "$Round_Current_Step_Total %" 
				Update_progressBar $Percent_Complete "Part $Current_Step_Number on $Total_Step : $Current_Step_Name" "Part $Current_Step_Number of $Total_Step"		
				$TSProgressUI.CloseProgressDialog()	
			}		
	} 	
while ($tsenv.Value("_SMSTSNextInstructionPointer") -ne $Total_Step) 
Close_modal_progress


