<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="ISO-8859-1"/>
<xsl:include href="header.xsl"/>
<xsl:include href="image.xsl"/>
<xsl:template match="diapositive">
	<html>
	<xsl:call-template name="header"></xsl:call-template>
	<body id="body">
	<div id="container">
	<div id="window">
        	<div id="title">
        		<p id="d_title"><xsl:value-of select="ville/@value"/>-<xsl:value-of select="situationgeo/@value"/></p>
        	</div>    
        	<div id="pictures">
			<xsl:apply-templates select="image"/>
        	</div>
        	<div id="desc">
        		<p id="d_desc"><xsl:value-of select="description"/></p>
        	</div> 
        	<div id="coord">
            		<p><span class="important2">Pour en savoir plus :</span></p>
            		<p><span class="important2">Tél: 05.59.138.300 ou Web: www.sb-immo.fr</span></p>
        	</div>
        	<div id="footer">
        		<table>
            		<tr>
                		<td class="left"><span id="d_ref"><xsl:value-of select="numbiens/@value"/></span></td>
        			<td class="right"><span id="d_priceRange"><xsl:value-of select="prix/@value"/></span></td>
                	</tr>
            		</table>
		</div>
	</div>
	</div>
	</body>
	</html>
  </xsl:template>
</xsl:stylesheet>
