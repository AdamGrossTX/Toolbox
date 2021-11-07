Get-CimInstance -Namespace "root\SMS\Site_PS1" -Query 'SELECT SMS_R_System.Name FROM SMS_R_System WHERE (Name != "CM01")' -ComputerName localhost | Select Name
