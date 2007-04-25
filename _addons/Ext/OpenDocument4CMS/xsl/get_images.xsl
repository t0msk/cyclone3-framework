<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xlink="http://www.w3.org/1999/xlink"
 xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
 xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
 >

<xsl:output method="xml" omit-xml-declaration="yes"/>

<xsl:template match="/">
	<images>
		<xsl:apply-templates/>
	</images>
</xsl:template>

<xsl:template match="*">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="draw:image">
	<image>
		<src><xsl:value-of select="@xlink:href"/></src>
	</image>
</xsl:template>

</xsl:stylesheet>
