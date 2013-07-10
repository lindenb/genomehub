<?xml version='1.0' encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
	xmlns:u="http://uniprot.org/uniprot"
	version='1.0'
	>

<xsl:output method="text"  encoding="UTF-8" />

<xsl:template match="/">
<xsl:apply-templates select="u:uniprot/u:entry|GBSet/GBSeq"/>
</xsl:template>

<xsl:template match="u:entry">
<xsl:value-of select="concat('&gt;',generate-id(.))"/>
<xsl:text>
</xsl:text>
<xsl:value-of select="normalize-space(translate(u:sequence,'&#10; ',''))"/>
<xsl:text>
</xsl:text>
</xsl:template>


<xsl:template match="GBSeq">
<xsl:value-of select="concat('&gt;',generate-id(.))"/>
<xsl:text>
</xsl:text>
<xsl:value-of select="normalize-space(GBSeq_sequence)"/>
<xsl:text>
</xsl:text>
</xsl:template>

</xsl:stylesheet>
