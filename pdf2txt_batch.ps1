###############################################################################
# Part of the Quantum Science & Technology in Dutch Newspapers (QSTDN) project
###############################################################################
# By Thomas Rothe 
# Copyright (c) 2022 Leiden University
################################################################################
# Converts .pdf to .txt files using MS Word as backend
# 
# Note: Requires Windoes 10/11 with .NET 3.5 or newer and MS Word 2013 or newer installed
# On first run, you may be prompted with "Word will now convert your PDF to an editable...."
# Please check the checkbox "[X] Don't show this message again" and hit OK.


$sourcepath = "[INSERT DATAPATH HERE]\national_newspapers_09-21\complete_data\"


# $exportFormat = [Microsoft.Office.Interop.Word.WdSaveFormat]::wdFormatUnicodeText

$wdTypes = Add-Type -AssemblyName 'Microsoft.Office.Interop.Word' -Passthru
$wdSaveFormat = $wdTypes | Where {$_.Name -eq "wdSaveFormat"}
$exportFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatUnicodeText")

$outputpath = "$($sourcepath)txt\"
[System.IO.Directory]::CreateDirectory($outputpath) 

$wrd = New-Object -ComObject "Word.Application" 
$files = Get-ChildItem $sourcepath -Filter "*.pdf"

$i = 1
foreach ($file in $files) {

    $txt_filepath = "$($outputpath)\$($file.BaseName).txt"
    $doc = $wrd.Documents.Open($file.FullName)
    $doc.SaveAs([ref] $txt_filepath, [ref] $exportFormat)
    $doc.Close()

    [int]$Percent = $i / $files.count * 100
    Write-Progress -Activity "Converting pdf to txt files" -Status "$Percent% Complete:" -PercentComplete $Percent 
}