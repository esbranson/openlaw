<#
 .Synopsis
  Import USLM.

 .Description
  Import USLM sections from an XmlDocument as PSCustomObject[].

 .Parameter Document
  The XmlDocument to parse.

 .Example
   Import-Module './AkomaNtoso.psm1'
   $billUrl = 'https://www.govinfo.gov/link/bills/117/hr/1319?link-type=uslm'
   $actUrl = 'https://www.govinfo.gov/link/plaw/117/public/2?link-type=uslm'
   $compsUrl = 'https://www.govinfo.gov/content/pkg/COMPS-16472/uslm/COMPS-16472.xml'
   $bill = irm $billUrl | Import-Uslm
   $act = irm $actUrl | Import-Uslm
   $comps = irm $compsUrl | Import-Uslm
   Compare-Object $bill.Num $act.Num
   Compare-Object $act.Num $comps.Num
#>
function Import-Uslm {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]$Document
    )

    Process {
        #if ($null -eq $Document) {return} # TODO Not needed if sanity checks all handle nullable variables and the default is return.
        if ($Document -is [xml]) {} # TODO Check that it's Akoma Ntoso.
        elseif ($Document -is [string]) { try { $Document = [xml](Get-Content $Document) } catch { return } }
        elseif ($Document -is [object[]]) { return ($Document | Import-Uslm) }
        else { return }

        $nsmgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $Document.NameTable
        $nsmgr.AddNamespace("uslm", "http://schemas.gpo.gov/xml/uslm");
        $Document.DocumentElement.SelectNodes($xPathSection, $nsmgr).forEach{
            # TODO Should we sanity check $_ type?
            $num = Get-XmlAttributeValue $_.SelectSingleNode($xPathNumAttr, $nsmgr)
            $heading = Get-XmlInnerText $_.SelectSingleNode($xPathHeading, $nsmgr)
            $_.SelectNodes($xPathRemoveAll, $nsmgr).ForEach{ $_.ParentNode.RemoveChild($_)>$null } # TODO This leaves errant spaces.
            [PSCustomObject]@{
                PSTypeName = "AknSection";
                CookedId   = Get-AknId $_ $nsmgr;
                UscId      = Get-XmlAttributeValue $_.SelectSingleNode($xPathUSCIdentifierAttr, $nsmgr);
                Id         = Get-XmlAttributeValue $_.Attributes["identifier"];
                Num        = $num;
                Heading    = $heading;
                Content    = Get-XmlInnerText $_.SelectSingleNode($xPathSelf, $nsmgr);
            }
        }
    }

    Begin {
        $xPathSection = "//uslm:section[not(ancestor::uslm:quotedContent)]"
        $xPathUSCIdentifierAttr = "./uslm:editorialNote[@role='uscRef']/uslm:ref/@href"
        $xPathNumAttr = "./uslm:num/@value"
        $xPathHeading = "./uslm:heading"
        $xPathSelf = "."
        $xPathRemoveAll = "./uslm:num|./uslm:heading|.//uslm:editorialNote[@role='uscRef']|.//*[self::uslm:footnote or self::uslm:sourceCredit or self::uslm:sidenote or self::uslm:page]"
        function Get-XmlAttributeValue([System.Xml.XmlAttribute]$obj) { if ($obj) { $obj.Value } }
        function Get-XmlInnerText([System.Xml.XmlNode]$obj) { if ($obj) { $obj.InnerText } }
        function Get-AknId([System.Xml.XmlElement]$Element, [System.Xml.XmlNamespaceManager]$nsmgr) {
            while ($Element) {
                $UscId = $Element.SelectSingleNode($xPathUSCIdentifierAttr, $nsmgr)
                if ($UscId -is [System.Xml.XmlAttribute]) { return $UscId.Value }
                $Id = $Element.Attributes["identifier"]
                if ($Id -is [System.Xml.XmlAttribute]) { return $Id.Value }
                $Element = $Element.ParentNode
            }
        }
    }
}
Update-TypeData -TypeName "AknSection" -DefaultDisplayPropertySet "Num", "Heading" -DefaultKeyPropertySet "Num" -ErrorAction SilentlyContinue
Export-ModuleMember -Function Import-Uslm

<#
 .Synopsis
  Import Akoma Ntoso.

 .Description
  Import Akoma Ntoso sections from an XmlDocument as PSCustomObject[].

 .Parameter Document
  The XmlDocument to parse.

 .Example
   Import-Module './AkomaNtoso.psm1'
   $actUrl = 'https://www.legislation.gov.uk/ukpga/1982/11/data.akn'
   irm $actUrl | Import-Akn | Format-List *
#>
function Import-Akn {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]$Document
    )

    Process {
        #if ($null -eq $Document) {return} # TODO Not needed if sanity checks all handle nullable variables and the default is return.
        if ($Document -is [xml]) {} # TODO Check that it's Akoma Ntoso.
        elseif ($Document -is [string]) { try { $Document = [xml](Get-Content $Document) } catch { return } }
        elseif ($Document -is [object[]]) { return ($Document | Import-Akn) }
        else { return }

        $nsmgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $Document.NameTable
        $nsmgr.AddNamespace("akn", "http://docs.oasis-open.org/legaldocml/ns/akn/3.0");
        $Document.DocumentElement.SelectNodes($xPathSection, $nsmgr).forEach{
            # TODO Should we sanity check $_ type?
            $num = Get-XmlInnerText $_.SelectSingleNode($xPathNumAttr, $nsmgr)
            $heading = Get-XmlInnerText $_.SelectSingleNode($xPathHeading, $nsmgr)
            $_.SelectNodes($xPathRemoveAll, $nsmgr).ForEach{ $_.ParentNode.RemoveChild($_)>$null } # TODO This leaves errant spaces.
            [PSCustomObject]@{
                PSTypeName = "AknSection";
                Id         = Get-XmlAttributeValue $_.Attributes["eId"];
                Num        = $num;
                Heading    = $heading;
                Content    = Get-XmlInnerText $_.SelectSingleNode($xPathSelf, $nsmgr);
            }
        }
    }

    Begin {
        $xPathSection = "//akn:section[not(ancestor::akn:hcontainer)]"
        $xPathNumAttr = "./akn:num"
        $xPathHeading = "./akn:heading"
        $xPathSelf = "."
        $xPathRemoveAll = "./akn:num|./akn:heading"
        function Get-XmlAttributeValue([System.Xml.XmlAttribute]$obj) { if ($obj) { $obj.Value } }
        function Get-XmlInnerText([System.Xml.XmlNode]$obj) { if ($obj) { $obj.InnerText.Trim() } }
    }
}
Export-ModuleMember -Function Import-Akn
