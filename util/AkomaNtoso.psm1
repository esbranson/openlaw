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
        [switch]$IncludeAll
    )

    Process {
        #
        # Parse the user input. Be flexible.
        #

        if ($null -eq $Document) {return} # TODO Not needed if sanity checks all handle nullable variables and the default is return.

        if ($Document -is [xml]) {} # TODO Check that it's Akoma Ntoso.
        elseif ($Document -is [string] -and [System.Uri]::IsWellFormedUriString($Document, [System.UriKind]::Absolute)) {
            $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
            $proxyParameter = @{}
            if ($proxy.GetProxy($Document)) { $proxyParameter = @{Proxy = $proxy.GetProxy($Document); ProxyUseDefaultCredentials = $true } }
            $Document = Invoke-RestMethod $Document @proxyParameter # TODO Why is this not terminating without explicitly throwing?
        }
        elseif ($Document -and $Document.GetType() -in @([string], [System.IO.Stream], [System.IO.TextReader], [System.Xml.XmlReader])) {
            $DocumentInput = $Document
            $Document = [System.Xml.XmlDocument]::new()
            $Document.Load($DocumentInput)
        }
        elseif ($Document -is [object[]]) { return ($Document | Import-Akn) }
        else { return } # TODO Respectfully throw.
        if ($null -eq $Document -or $Document -isnot [System.Xml.XmlDocument]) {return} 

        ([AkomaNtosoDocument]::new($Document, $IncludeAll)).Sections
    }
}

class AkomaNtosoSection {
    [string[]]$Id
    [string]$Num
    [string]$Heading
    [boolean]$IsRepealed
    [string]$Content

    hidden static [string]$xPathUSCIdentifierAttr = "./uslm:editorialNote[@role='uscRef']/uslm:ref/@href"
    hidden static [string]$xPathUSCSidenoteIdentifierAttr = "./uslm:sidenote//uslm:ref/@href" # TODO
    hidden static [string]$xPathNumAttr = "./akn:num|./uslm:num/@value"
    hidden static [string]$xPathHeading = "./akn:heading|./uslm:heading"
    hidden static [string]$xPathSelf = "."
    hidden static [string]$xPathRemoveAll = "./akn:num|./akn:heading|./uslm:num|./uslm:heading|.//uslm:editorialNote[@role='uscRef']|.//*[self::uslm:footnote or self::uslm:sourceCredit or self::uslm:sidenote or self::uslm:page]"
    hidden static [string]$reIsRepealed = '^([. ]+)$' # TODO Process notes.

    AkomaNtosoSection(
        [System.Xml.XmlNode]$Xml,
        [System.Xml.XmlNamespaceManager]$XmlNamespaceManager
    ){
        $this.Id = [AkomaNtosoSection]::GetId($Xml, $XmlNamespaceManager)
        $this.Num = [AkomaNtosoSection]::GetNum($Xml, $XmlNamespaceManager)
        $this.Heading = [AkomaNtosoSection]::GetXmlInnerText($_.SelectSingleNode([AkomaNtosoSection]::xPathHeading, $XmlNamespaceManager))
        $this.IsRepealed = [AkomaNtosoSection]::TestHeadingIsRepealed($this.Heading)
        $this.Content = [AkomaNtosoSection]::GetXmlInnerText($_.SelectSingleNode([AkomaNtosoSection]::xPathSelf, $XmlNamespaceManager))
    }

    static [string[]]GetId(
        [System.Xml.XmlNode]$Element,
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    ){
        # Amoma Ntoso eID
        $AknId = $Element.Attributes["eId"]
        if ($AknId) {$AknId = $AknId.Value}

        # USLM identifier
        $UslmId = [AkomaNtosoSection]::GetXmlAttributeValue($Element.Attributes["identifier"])

        # USLM USC identifier
        $UslmUscId = [AkomaNtosoSection]::GetXmlAttributeValue($Element.SelectSingleNode([AkomaNtosoSection]::xPathUSCIdentifierAttr, $NamespaceManager))
        $UslmUscId = [AkomaNtosoSection]::GetXmlAttributeValue($Element.SelectSingleNode([AkomaNtosoSection]::xPathUSCSidenoteIdentifierAttr, $NamespaceManager))

        return (@($AknId, $UslmId, $UslmUscId, $UslmUscId) | ? {$_})
    }

    static [string]GetNum(
        [System.Xml.XmlNode]$Element,
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    ){
        $AknNum = [AkomaNtosoSection]::GetXmlInnerText($Element.SelectSingleNode([AkomaNtosoSection]::xPathNumAttr, $NamespaceManager))
        $UslmNum = [AkomaNtosoSection]::GetXmlAttributeValue($Element.SelectSingleNode([AkomaNtosoSection]::xPathNumAttr, $NamespaceManager))

        return ($AknNum ? $AknNum : $UslmNum)
    }

    static [boolean]TestHeadingIsRepealed([string]$heading){
        if ($heading -match [AkomaNtosoSection]::reIsRepealed) {return $true}
        return $false
    }

    static [string]GetXmlAttributeValue($obj){if ($obj -is [System.Xml.XmlAttribute]) {return $obj.Value}; return $null;}
    static [string]GetXmlInnerText([System.Xml.XmlNode]$obj){if ($obj -and $obj.InnerText) {return $obj.InnerText.Trim()}; return $null;}
}

class AkomaNtosoDocument {
    [AkomaNtosoSection[]]$Sections
    [int]$Count

    hidden static [string]$xPathSection = "//akn:section[not(ancestor::akn:hcontainer)]|//uslm:section[not(ancestor::uslm:quotedContent)]"
    hidden static [string]$xPathSectionAll = "//akn:section|//uslm:section"

    AkomaNtosoDocument(
        [System.Xml.XmlDocument]$XmlDocument,
        [switch]$IncludeAll
    ){
        $path = [AkomaNtosoDocument]::xPathSection
        if ($IncludeAll) {$path = [AkomaNtosoDocument]::xPathSectionAll}

        $XmlNamespaceManager = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $XmlDocument.NameTable
        $XmlNamespaceManager.AddNamespace("akn", "http://docs.oasis-open.org/legaldocml/ns/akn/3.0")
        $XmlNamespaceManager.AddNamespace("uslm", "http://schemas.gpo.gov/xml/uslm")

        $Nodes = $XmlDocument.DocumentElement.SelectNodes($path, $XmlNamespaceManager)
        $this.Count = $Nodes.Count
        $this.Sections = $Nodes.forEach{
            # TODO Should we sanity check $_ type?
            [AkomaNtosoSection]::new($_, $XmlNamespaceManager)
        }
    }
}

Update-TypeData -TypeName "AkomaNtosoDocument" -DefaultDisplayPropertySet "Count","Sections" -DefaultKeyPropertySet "Sections" -ErrorAction SilentlyContinue
Update-TypeData -TypeName "AkomaNtosoSection" -DefaultDisplayPropertySet "Num", "Heading" -DefaultKeyPropertySet "Num" -ErrorAction SilentlyContinue
New-Alias Import-Akn Import-AkomaNtoso
Export-ModuleMember -Function * -Alias *
