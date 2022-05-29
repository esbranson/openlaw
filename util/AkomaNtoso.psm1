<#
 .Synopsis
  Import Akoma Ntoso.

 .Description
  Import Akoma Ntoso or USLM sections.

 .Parameter Document
  The object, path, URI or array thereof to parse.

 .Parameter IncludeRepealed
  Include repealed sections.

 .Example
   Import-Module './AkomaNtoso.psm1'
   $Bill = Import-Akn 'https://www.govinfo.gov/link/bills/117/hr/1319?link-type=uslm'
   $Act = Import-Akn 'https://www.govinfo.gov/link/plaw/117/public/2?link-type=uslm'
   $Comps = Import-Akn 'https://www.govinfo.gov/content/pkg/COMPS-16472/uslm/COMPS-16472.xml'
   Compare-Object $Bill.Num $Act.Num
   Compare-Object $Act.Num $Comps.Num
   Import-Akn 'https://www.legislation.gov.uk/ukpga/1982/11/data.akn' | Format-List *
#>
function Import-AkomaNtoso {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]$Document,
        [switch]$IncludeRepealed
    )

    Process {
        #if ($null -eq $Document) {return} # TODO Not needed if sanity checks all handle nullable variables and the default is return.
        if ($Document -is [xml]) {} # TODO Check that it's Akoma Ntoso.
        elseif ($Document -is [string] -and [System.Uri]::IsWellFormedUriString($Document, [System.UriKind]::Absolute)) {
            $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
            $proxyParameter = @{}
            if ($proxy.GetProxy($Document)) { $proxyParameter = @{Proxy = $proxy.GetProxy($Document); ProxyUseDefaultCredentials = $true } }
            try { $Document = Invoke-RestMethod $Document @proxyParameter -ErrorAction Stop } catch { throw } # TODO Why is this not terminating without explicitly throwing?
        }
        elseif ($Document -and $Document.GetType() -in @([string], [System.IO.Stream], [System.IO.TextReader], [System.Xml.XmlReader])) {
            $DocumentInput = $Document
            $Document = [System.Xml.XmlDocument]::new()
            $Document.Load($DocumentInput)
        }
        elseif ($Document -is [object[]]) { return ($Document | Import-Akn) }
        else { return } # TODO Respectfully throw.

        $nsmgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $Document.NameTable
        $nsmgr.AddNamespace("akn", "http://docs.oasis-open.org/legaldocml/ns/akn/3.0")
        $nsmgr.AddNamespace("uslm", "http://schemas.gpo.gov/xml/uslm")
        $Document.DocumentElement.SelectNodes($xPathSection, $nsmgr).forEach{
            # TODO Should we sanity check $_ type?
            $Id = Get-Id $_ $nsmgr
            $Num = Get-Num $_ $nsmgr
            $Heading = Get-XmlInnerText $_.SelectSingleNode($xPathHeading, $nsmgr)
            $IsRepealed = Test-HeadingIsRepealed $heading # TODO

            $_.SelectNodes($xPathRemoveAll, $nsmgr).ForEach{ $_.ParentNode.RemoveChild($_)>$null } # TODO This leaves errant spaces.
            $Content = Get-XmlInnerText $_.SelectSingleNode($xPathSelf, $nsmgr)

            [PSCustomObject][ordered]@{
                PSTypeName = "AknSection";
                Id         = $Id;
                Num        = $Num;
                Heading    = $Heading;
                IsRepealed = $IsRepealed;
                Content    = $Content;
            } | 
            Where-Object { $IncludeRepealed -or -not $_.IsRepealed }
        }
    }

    Begin {
        $xPathSection = "//akn:section[not(ancestor::akn:hcontainer)]|//uslm:section[not(ancestor::uslm:quotedContent)]"
        $xPathUSCIdentifierAttr = "./uslm:editorialNote[@role='uscRef']/uslm:ref/@href"
        $xPathUSCSidenoteIdentifierAttr = "./uslm:sidenote//uslm:ref/@href" # TODO
        $xPathNumAttr = "./akn:num|./uslm:num/@value"
        $xPathHeading = "./akn:heading|./uslm:heading"
        $xPathSelf = "."
        $xPathRemoveAll = "./akn:num|./akn:heading|./uslm:num|./uslm:heading|.//uslm:editorialNote[@role='uscRef']|.//*[self::uslm:footnote or self::uslm:sourceCredit or self::uslm:sidenote or self::uslm:page]"
        $reIsRepealed = '^([. ]+)$' # TODO Process notes.

        function Get-XmlAttributeValue($obj) { if ($obj -is [System.Xml.XmlAttribute]) { $obj.Value } }

        function Get-XmlInnerText([System.Xml.XmlNode]$obj) { if ($obj -and $obj.InnerText) { $obj.InnerText.Trim() } }

        <#
        .SYNOPSIS
        Get all identifiers of a node.
        #>
        function Get-Id([System.Xml.XmlNode]$Element, [System.Xml.XmlNamespaceManager]$nsmgr) {
            # USLM USC identifier
            $UslmUscId = Get-XmlAttributeValue $Element.SelectSingleNode($xPathUSCIdentifierAttr, $nsmgr)
            if ($UslmUscId) { $UslmUscId }
            $UslmUscIdSidenote = Get-XmlAttributeValue $Element.SelectSingleNode($xPathUSCSidenoteIdentifierAttr, $nsmgr)
            if ($UslmUscIdSidenote) { $UslmUscIdSidenote }

            # Amoma Ntoso eID
            $AknId = $Element.Attributes["eId"]
            if ($AknId) { $AknId.Value }

            # USLM identifier
            $UslmId = Get-XmlAttributeValue  $Element.Attributes["identifier"]
            if ($UslmId) { $UslmId }
        }

        function Get-Num([System.Xml.XmlNode]$Element, [System.Xml.XmlNamespaceManager]$nsmgr) {
            $AknNum = Get-XmlInnerText $Element.SelectSingleNode($xPathNumAttr, $nsmgr)
            if ($AknNum) { return $AknNum }
            $UslmNum = Get-XmlAttributeValue $_.SelectSingleNode($xPathNumAttr, $nsmgr)
            if ($UslmNum) { return $UslmNum }
        }

        function Test-HeadingIsRepealed([string]$heading) { if ($heading -match $reIsRepealed) { $true } else { $false } }
    }
}
Update-TypeData -TypeName "AknSection" -DefaultDisplayPropertySet "Num", "Heading" -DefaultKeyPropertySet "Num" -ErrorAction SilentlyContinue
New-Alias Import-Akn Import-AkomaNtoso
Export-ModuleMember -Function * -Alias *
