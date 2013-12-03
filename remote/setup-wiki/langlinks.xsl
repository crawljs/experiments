<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="//div[@id='p-lang']/div/ul/li">
    <xsl:variable name="href" select="a/@href"/>
    <!--Repeat for every language you want -->
    <xsl:if test="contains($href, '/bs/')">
      <xsl:call-template name="langlink">
        <xsl:with-param name="lang" select="'bs'"/>
        <xsl:with-param name="href" select="$href"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="contains($href, '/bn/')">
      <xsl:call-template name="langlink">
        <xsl:with-param name="lang" select="'bn'"/>
        <xsl:with-param name="href" select="$href"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="langlink">
    <xsl:param name="lang"/>
    <xsl:param name="href"/>
    <li>
      <a href="http://{$lang}.wikipedia.org/{substring-after($href, concat('/', $lang, '/'))}">
        <xsl:value-of select="a"/>
      </a>
    </li>
  </xsl:template>
</xsl:stylesheet>
