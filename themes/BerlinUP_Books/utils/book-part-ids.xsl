<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="xml" standalone="no" doctype-public="-//NLM//DTD BITS Book Interchange DTD v2.2 20250930//EN"  doctype-system="http://jats.nlm.nih.gov/extensions/bits/2.2/BITS-book2-2.dtd" indent="yes" />

    <!-- Identity transform: copies everything by default -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Match book-part elements -->
    <xsl:template match="book-part">
        <xsl:copy>
            <!-- Copy all attributes except 'id' -->
            <xsl:apply-templates select="@*[name() != 'id']"/>

            <!-- Generate a unique ID using xsl:number -->
            <xsl:attribute name="id">
                <xsl:text>bp</xsl:text>
                <xsl:number level="any" count="book-part" format="1"/>
            </xsl:attribute>

            <!-- Process child nodes -->
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
