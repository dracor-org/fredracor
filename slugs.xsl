<!-- stylesheet used to extract slugs from ids.xml in tc2dracor -->
<xsl:stylesheet version="1.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/">
    <xsl:apply-templates select="//play"/>
  </xsl:template>
  <xsl:template match="play[@slug]">
    <xsl:value-of select="@file"/>
    <xsl:text>:</xsl:text>
    <xsl:value-of select="@slug"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
