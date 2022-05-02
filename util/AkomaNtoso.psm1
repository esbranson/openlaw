<#
 .Synopsis
  Output Akoma Ntoso sections.

 .Description
  Output Akoma Ntoso sections as PSCustomObject[].

 .Parameter Document
  The XmlDocument to parse.

 .Example
   Import-Module './AkomaNtoso.psm1'
   $billUrl = 'https://www.govinfo.gov/link/bills/117/hr/1319?link-type=uslm'
   $actUrl = 'https://www.govinfo.gov/link/plaw/117/public/2?link-type=uslm'
   $compsUrl = 'https://www.govinfo.gov/content/pkg/COMPS-16472/uslm/COMPS-16472.xml'
   $bill = irm $billUrl | Format-Akn
   $act = irm $actUrl | Format-Akn
   $comps = irm $compsUrl | Format-Akn
   Compare-Object $bill.Num $act.Num
   Compare-Object $act.Num $comps.Num
#>
function Format-Akn {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]$Document
    )

    Process {
        #if ($null -eq $Document) {return} # TODO Not needed if sanity checks all handle nullable variables and the default is return.
        if ($Document -is [xml]) {} # TODO Check that it's Akoma Ntoso.
        elseif ($Document -is [string]) { try { $Document = [xml](Get-Content $Document) } catch { return } }
        elseif ($Document -is [object[]]) { return ($Document | Format-Akn) }
        else { return }

        $nsmgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $Document.NameTable
        $nsmgr.AddNamespace("uslm", "http://schemas.gpo.gov/xml/uslm");
        $Document.DocumentElement.SelectNodes($xPathSection, $nsmgr).forEach{
            # TODO Should we sanity check $_ type?
            [PSCustomObject]@{
                PSTypeName = "AknSection";
                CookedId   = Get-AknId $_ $nsmgr;
                UscId      = Get-XmlAttributeValue $_.SelectSingleNode($xPathUSCIdentifierAttr, $nsmgr);
                Id         = Get-XmlAttributeValue $_.Attributes["identifier"];
                Num        = Get-XmlAttributeValue $_.SelectSingleNode($xPathNumAttr, $nsmgr);
                Content    = [string]::Join(' ', (Get-XmlText $_));
            }
        }
    }

    Begin {
        $xPathSection = "//uslm:section[not(ancestor::uslm:quotedContent)]"
        $xPathUSCIdentifierAttr = "./uslm:editorialNote[@role='uscRef']/uslm:ref/@href"
        $xPathNumAttr = "./uslm:num/@value"
        function Get-XmlAttributeValue($obj) { if ($obj -is [System.Xml.XmlAttribute]) { $obj.Value } }
        function Get-AknId([System.Xml.XmlElement]$Element, [System.Xml.XmlNamespaceManager]$nsmgr) {
            while ($Element) {
                $UscId = $Element.SelectSingleNode($xPathUSCIdentifierAttr, $nsmgr)
                if ($UscId -is [System.Xml.XmlAttribute]) { return $UscId.Value }
                $Id = $Element.Attributes["identifier"]
                if ($Id -is [System.Xml.XmlAttribute]) { return $Id.Value }
                $Element = $Element.ParentNode
            }
        }
        function Get-XmlText([System.Xml.XmlNode]$Node, [int]$allownum = 0) {
            foreach ($child in $Node.ChildNodes) {
                if ($child.NodeType -eq [System.Xml.XmlNodeType]::Text -or $child.NodeType -eq [System.Xml.XmlNodeType]::CDATA) {
                    $child.Value.Trim()
                }
                if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element -and $child.Name -notin @('editorialNote') -and ($allownum -or $child.Name -notin @('num'))) {
                    Get-XmlText $child -allownum 1
                }
            }
        }
    }
}
Update-TypeData -TypeName "AknSection" -DefaultDisplayPropertySet "Num", "Content" -DefaultKeyPropertySet "Num"
Export-ModuleMember -Function Format-Akn
