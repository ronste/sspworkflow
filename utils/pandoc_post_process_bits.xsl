<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="xs" version="2.0">

    <xsl:param name="metadata-uri" as="xs:string" select="'../work/metadata/metadata.yaml'"/>
    <xsl:variable name="metadata-doc-uri" as="xs:anyURI" select="resolve-uri($metadata-uri, static-base-uri())"/>
    <xsl:variable name="metadata-text" as="xs:string" select="if (unparsed-text-available($metadata-doc-uri)) then unparsed-text($metadata-doc-uri) else ''"/>
    <xsl:variable name="toc-line" as="xs:string?" select="(for $line in tokenize($metadata-text, '\r?\n') return if (matches($line, '^\s*tocLabel\s*:')) then replace($line, '^\s*tocLabel\s*:\s*', '') else ())[1]"/>
    <xsl:variable name="toc-label" as="xs:string" select="if ($toc-line) then normalize-space(translate(replace($toc-line, '\s+#.*$', ''), '&quot;''', '')) else 'inhalt'"/>
    <xsl:variable name="toc-id-candidates" as="xs:string*" select="distinct-values(($toc-label, lower-case($toc-label), replace(lower-case($toc-label), '\s+', '-')))"/>

    <xsl:output method="xml" standalone="no" doctype-public="-//NLM//DTD BITS Book Interchange DTD v2.2 20250930//EN"  doctype-system="http://jats.nlm.nih.gov/extensions/bits/2.2/BITS-book2-2.dtd" indent="yes" />

    <xsl:strip-space elements="*" />

    <!-- PRIMARY TEMPLATES -->

    <!-- Copy all major parts and apply sub-templates -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- handle front-matter -->
    <xsl:template match="//front-matter">
        <xsl:message>Processing front-matter ...</xsl:message>
        <xsl:copy>
            <!-- <xsl:apply-templates select="//sec[some $toc in $toc-id-candidates satisfies @id = $toc]" /> -->
            <xsl:apply-templates select="node()" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="//book-body">
        <xsl:message>Processing body ...</xsl:message>
        <book-body>
            <xsl:apply-templates select="sec[not(some $toc in $toc-id-candidates satisfies @id = $toc)]" />
        </book-body>
    </xsl:template>

    <!-- create chapters -->
    <xsl:template match="//book-body/sec[not(some $toc in $toc-id-candidates satisfies @id = $toc)]">
        <xsl:variable name="chapter_id" select="position()" />
        <xsl:message>
            <xsl:value-of select="concat('Chapter ', $chapter_id, ': ', @id)" />
        </xsl:message>
        <book-part id="chapter{$chapter_id}" book-part-type="chapter">
            <!-- <book-part-meta></book-part-meta> -->
            <body>
                <sec>
                    <xsl:apply-templates select="node()" />
                </sec>
            </body>
            <!-- <back></back> -->
        </book-part>
    </xsl:template>

    <!-- remove everything outside a chapter -->
    <xsl:template match="//book-body/*[not(self::sec)]"></xsl:template>

    <!-- handle table of contents -->
    <xsl:template match="//sec[some $toc in $toc-id-candidates satisfies @id = $toc]">
        <xsl:message>Processing TOC</xsl:message>
        <toc>
            <toc-title-group>
                <title>
                    <xsl:value-of select="title"/>
                </title>
            </toc-title-group>
            <xsl:apply-templates select="boxed-text"/>
        </toc>
    </xsl:template>

    <xsl:template match="//sec[some $toc in $toc-id-candidates satisfies @id = $toc]/boxed-text">
        <toc-entry>
            <xsl:apply-templates select="node()" />
        </toc-entry>
    </xsl:template>

        <!-- handle references to other chapters -->
        <xsl:template match="xref[not(@ref-type)]">
            <xsl:variable name="chapter_target" select="//*[@id=current()/@rid][1]" />
            <xsl:variable name="chapter_position" as="xs:integer?"
                select="if ($chapter_target/self::sec and $chapter_target/parent::book-body)
                        then count($chapter_target/preceding-sibling::sec[not(some $toc in $toc-id-candidates satisfies @id = $toc)]) + 1
                        else ()" />
            <xref>
                <xsl:attribute name="rid">
                    <xsl:choose>
                        <xsl:when test="exists($chapter_position)">
                            <xsl:text>chapter</xsl:text>
                            <xsl:value-of select="$chapter_position"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@rid"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:apply-templates select="node()" />
            </xref>
        </xsl:template>

    </xsl:stylesheet>