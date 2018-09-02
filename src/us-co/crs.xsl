<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="/CRS">
        <akomaNtoso>
            <act>
                <preface>
                    <xsl:apply-templates select="TITLE_NUM"/>
                    <xsl:apply-templates select="TITLE_TEXT"/>
                </preface>
                <body>
                    <xsl:apply-templates select="ARTICLE_NUM"/>
                    <!--<xsl:apply-templates select="SECTION_TEXT"/>-->
                </body>
            </act>
        </akomaNtoso>
    </xsl:template>

    <xsl:template match="TITLE_NUM">
        <docNumber><xsl:value-of select="normalize-space(text())"/></docNumber>
    </xsl:template>

    <xsl:template match="TITLE_TEXT">
        <docTitle><xsl:value-of select="normalize-space(text())"/></docTitle>
    </xsl:template>

    <xsl:key name="prev" match="ARTICLE_NUM" use="count(preceding-sibling::ARTICLE_NUM)"/>

    <xsl:template match="ARTICLE_NUM">
        <article>
            <num><xsl:value-of select="normalize-space(text())"/></num>
            <heading><xsl:value-of select="normalize-space(following-sibling::ARTICLE_TEXT)"/></heading>
            <intro></intro>
            <xsl:apply-templates select="following-sibling::SECTION_TEXT[preceding-sibling::ARTICLE_NUM[1]=current()]"/>
        </article>
    </xsl:template>

    <xsl:template match="SECTION_TEXT">
        <section>
            <num><xsl:value-of select="normalize-space(.//CATCH_LINE/RHFTO)"/></num>
            <heading><xsl:value-of select="normalize-space(.//CATCH_LINE/RHFTO/following-sibling::M/following-sibling::text())"/></heading>
        </section>
    </xsl:template>
</xsl:stylesheet>

