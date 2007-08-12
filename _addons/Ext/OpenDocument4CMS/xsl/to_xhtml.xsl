<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
 xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
 xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
 xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
 >

<xsl:output method="html" omit-xml-declaration="no"/>

<xsl:template match="/">
	<div class="odf_">
		<xsl:apply-templates/>
	</div>
</xsl:template>

<xsl:template match="office:document-content">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="office:body">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="office:text">
	<xsl:apply-templates/>
</xsl:template>

<!-- ignore -->
<xsl:template match="
	office:font-face-decls|
	office:automatic-styles
	"/>


<xsl:template match="draw:frame">
	<div class="odf_frame">
		<xsl:apply-templates/>
	</div>
</xsl:template>

<xsl:template match="draw:text-box">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="text:p">
	<p>
		<xsl:apply-templates/>
	</p>
</xsl:template>

<xsl:template match="text:list">
	<ul>
		<xsl:apply-templates/>
	</ul>
</xsl:template>

<xsl:template match="text:list-item">
	<li>
		<xsl:apply-templates/>
	</li>
</xsl:template>

<xsl:template match="text:span">
	<span><xsl:apply-templates/></span>
</xsl:template>

<!-- heading -->

<xsl:template match="text:h">
	<h2><xsl:apply-templates/></h2>
</xsl:template>

<!-- tables -->

<xsl:template match="table:table">
	<table border="1"><xsl:apply-templates/></table>
</xsl:template>

<xsl:template match="table:table-row">
	<tr><xsl:apply-templates/></tr>
</xsl:template>

<xsl:template match="table:table-cell">
	<td><xsl:apply-templates/></td>
</xsl:template>

<xsl:template match="table:table-column"/>

</xsl:stylesheet>
