<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>
	<xsl:template match="image">
		<xsl:element name="img">
			<xsl:attribute name="src">images/<xsl:value-of select="@id"/></xsl:attribute>
			<xsl:attribute name="height">225</xsl:attribute>
			<xsl:attribute name="width">300</xsl:attribute>
			<xsl:attribute name="class">thumbnail</xsl:attribute>
		</xsl:element>
	</xsl:template> 
</xsl:stylesheet>