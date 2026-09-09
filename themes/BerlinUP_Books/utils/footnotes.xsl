<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="xml" standalone="no" doctype-public="-//NLM//DTD BITS Book Interchange DTD v2.2 20250930//EN"  doctype-system="http://jats.nlm.nih.gov/extensions/bits/2.2/BITS-book2-2.dtd" indent="yes" />

    <!-- Match the root element -->
    <xsl:template match="/">
        <xsl:apply-templates select="*"/>
    </xsl:template>

    <!-- Match each book-part element -->
    <xsl:template match="book-part">
        <xsl:copy>
            <!-- Copy all attributes and child elements of book-part -->
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Match fn elements -->
    <xsl:template match="fn">
        <xsl:copy>
            <!-- Copy all attributes of fn -->
            <xsl:apply-templates select="@*"/>
            <!-- Generate a new unique ID for the fn element, prefixed with the book-part ID -->
            <xsl:attribute name="id">
                <xsl:value-of select="concat(ancestor::book-part/@id, '_', @id)"/>
            </xsl:attribute>
            <!-- Copy all child elements of fn -->
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Match xref elements that reference fn IDs -->
    <xsl:template match="xref[@rid]">
        <xsl:copy>
            <!-- Copy all attributes of xref -->
            <xsl:apply-templates select="@*"/>
            <!-- Update the rid attribute to point to the new prefixed fn ID -->
            <xsl:attribute name="rid">
                <xsl:value-of select="concat(ancestor::book-part/@id, '_', @rid)"/>
            </xsl:attribute>
            <!-- Copy all child elements of xref -->
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Match aff and corresp elements and prefix their IDs -->
    <xsl:template match="aff|corresp">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="id">
                <xsl:value-of select="concat(ancestor::book-part/@id, '_', @id)"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Identity template to copy everything else as-is -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
