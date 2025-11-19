for ($i=1; $i -lt 45; $i++) {
  $name = [string]::Format("CA{0}", $i.ToString("00"));
  New-Item -Path "C:\Users\Ole Anders Herland\OneDrive - Marcello Consulting AS\Forvaltning - Documents\General\Kunder\Eika Gruppen AS\ISAE 3402 revisjon\2025 Revisjon" -Name $name -ItemType "directory"
}