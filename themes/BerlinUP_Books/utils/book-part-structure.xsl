<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Identity transform: copies everything by default -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Match the books root book-body element to process all book-part children -->
    <xsl:template match="book/book-body">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Append each preface's following Beitrag siblings to its body. -->
    <xsl:template match="book-part[@book-part-type = 'preface']/body">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>

            <xsl:apply-templates
                select="../following-sibling::book-part[
                    @book-part-type = 'Beitrag'
                    and generate-id(
                        preceding-sibling::book-part[
                            @book-part-type = 'preface'
                        ][1]
                    ) = generate-id(current()/..)
                ]"
                mode="nested-contribution"/>
        </xsl:copy>
    </xsl:template>

    <!-- Copy contributions when they are inserted into a preface body. -->
    <xsl:template match="book-part" mode="nested-contribution">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Do not emit Beiträge twice after moving them into a preface body. -->
    <xsl:template match="book/book-body/book-part[
        @book-part-type = 'Beitrag'
        and preceding-sibling::book-part[@book-part-type = 'preface']
    ]"/>

</xsl:stylesheet>
