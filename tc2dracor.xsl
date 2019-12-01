<?xml version="1.0" encoding="utf-8"?>
<!--
  Note: In order to preserve the formatting of the original documents as far as
  possible, this stylesheet manually indents the added elements.
-->
<xsl:stylesheet version="2.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <!-- We use indent=no to prevent Saxon to add unnecessary newlines. -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    omit-xml-declaration="no"
    indent="no"
  />

  <xsl:variable name="ids" select="document('ids.xml')"/>
  <xsl:variable name="orig-id" select="/tei:TEI/@xml:id"/>
  <xsl:variable
    name="dracor-id"
    select="$ids//play[@orig=$orig-id]/@dracor"
  />
  <xsl:variable
    name="play-wikidata-id"
    select="$ids//play[@orig=$orig-id]/@wikidata"
  />
  <xsl:variable name="castList" select="/tei:TEI//tei:castList"/>
  <xsl:variable
    name="editorial-cast"
    select="/tei:TEI//tei:div[@type='editorial']//tei:listPerson[@type='cast']"
  />

  <xsl:template match="/">
    <xsl:text>&#10;</xsl:text>
    <xsl:processing-instruction name="xml-stylesheet">type="text/css" href="../css/tei.css"</xsl:processing-instruction>
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates select="/tei:TEI"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- set xml:lang -->
  <xsl:template match="tei:TEI">
    <TEI xml:lang="fr">
      <xsl:text>&#10;  </xsl:text>
      <xsl:apply-templates select="/tei:TEI/*"/>
      <xsl:text>&#10;</xsl:text>
    </TEI>
  </xsl:template>

  <!-- remove xml:id from castList roles -->
  <xsl:template match="tei:role/@xml:id"></xsl:template>
  <!-- remove xml:id from castList roleGroup -->
  <xsl:template match="tei:roleGroup/@xml:id"></xsl:template>

  <!-- remove xml:id from tei:text -->
  <xsl:template match="tei:text[@xml:id]">
    <xsl:text>&#10;  </xsl:text>
    <text>
      <xsl:apply-templates/>
    </text>
  </xsl:template>

  <!-- add DraCor ID, wikidata ID for play -->
  <xsl:template match="tei:publicationStmt">
    <publicationStmt>
      <xsl:apply-templates/>
      <xsl:text>  </xsl:text>
      <idno type="orig">
        <xsl:value-of select="$orig-id"/>
      </idno>
      <xsl:text>&#10;        </xsl:text>
      <idno type="dracor" xml:base="https://dracor.org/id/">
        <xsl:value-of select="$dracor-id"/>
      </idno>
      <xsl:if test="$play-wikidata-id">
        <xsl:text>&#10;        </xsl:text>
        <idno type="wikidata" xml:base="https://www.wikidata.org/entity/">
          <xsl:value-of select="$play-wikidata-id"/>
        </idno>
      </xsl:if>
      <xsl:text>&#10;      </xsl:text>
    </publicationStmt>
  </xsl:template>

</xsl:stylesheet>
