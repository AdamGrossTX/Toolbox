[void] [System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
$inputXML = @"
<Window x:Name="Test" x:Class="Test.TestForm"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Test"
        mc:Ignorable="d"
        Title="Test"
        >
</Window>
"@

$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
[xml]$XAML = $inputXML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$form=[Windows.Markup.XamlReader]::Load( $reader )
$form.ShowDialog()
