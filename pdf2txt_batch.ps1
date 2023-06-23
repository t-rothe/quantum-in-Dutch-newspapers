###############################################################################
# Part of the Quantum in newspapers project
# By Thomas Rothe
################################################################################
# Converts .pdf to .txt files using Word as backend
# 
# Note: Requires Windoes 10/11 with .NET 3.5 or newer and MS Word 2013 or newer installed
# On first run, you may be prompted with "Word will now convert your PDF to an editable...."
# Please check the checkbox "[X] Don't show this message again" and hit OK.

# $sourcepath = "C:\Users\trothe\Downloads\test_box\"
$sourcepath = "S:\Sync\University\20212022_EPQS\data_files\national_newspapers_09-21\complete_data\"
# $sourcepath = "S:\Sync\University\20212022_EPQS\data_files\national_newspapers_09-21\complete_data\raw_downloads\20xx\labelled_backup\"
# $sourcepath = "S:\Sync\University\20212022_EPQS\data_files\national_newspapers_09-21\complete_data\2022_singledout\"
# $sourcepath = "S:\Sync\University\20212022_EPQS\data_files\national_newspapers_09-21\complete_data\2022_singledout\_2022_postselected\"
# $sourcepath = "S:\Sync\University\20212022_EPQS\data_files\national_newspapers_09-21\post_selection_data\"


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