<?xml version='1.0' encoding="UTF-8"?>
<!--
Author:
        Pierre Lindenbaum
        http://plindenbaum.blogspot.com
        
Motivation:
      transforms a genomehub.xml to Make

Usage :
      xsltproc genomehub2make.xsl genomehub.xml > Makefile
-->

<xsl:stylesheet
	xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
	version='1.0'
	>
<xsl:key name="entries" match="/genomeHub/accessions/acn" use="."/>
<xsl:output method="text"  encoding="UTF-8" />

<xsl:template match="/">
<xsl:apply-templates select="genomeHub"/>
</xsl:template>

<xsl:template match="genomeHub">
SHELL=/bin/bash
CURLPROXY= -x proxy-upgrade.univ-nantes.prive:3128 
TMPDIR=tmp
.PHONY=all clean <xsl:for-each select="genome"><xsl:value-of select="@id"/></xsl:for-each>
all: hub.txt

hub.txt: genomes.txt
	rm -f $@
	<xsl:choose>
		<xsl:when test="name">echo "hub <xsl:value-of select="name"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "hub untitled" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>
	<xsl:choose>
		<xsl:when test="shortLabel">echo "shortLabel <xsl:value-of select="shortLabel"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "shortLabel untitled" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>
	<xsl:choose>
		<xsl:when test="longLabel">echo "longLabel <xsl:value-of select="longLabel"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "longLabel untitled" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>
	echo "genomesFile genomes.txt" &gt;&gt; $@ ;
	<xsl:choose>
		<xsl:when test="email">echo "email <xsl:value-of select="email"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "longLabel me@nowhere.com" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>

genomes.txt: <xsl:for-each select="genome"><xsl:value-of select="@id"/></xsl:for-each>
	rm -f $@
	<xsl:for-each select="genome">echo "genome	<xsl:value-of select="@id"/>" &gt;&gt; $@ ;
	echo "trackDb	$(dir <xsl:value-of select="fasta"/>)trackDb.txt" &gt;&gt; $@ ;
	echo "twoBitPath	$(addsuffix .2bit,$(basename <xsl:value-of select="fasta"/>))" &gt;&gt; $@ ;
	<xsl:if test="email">echo "email	<xsl:value-of select="email"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="organism">echo "organism	<xsl:value-of select="organism"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="description">echo "description	<xsl:value-of select="description"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="defaultPos">echo "defaultPos	<xsl:value-of select="defaultPos"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="orderKey">echo "orderKey	<xsl:value-of select="orderKey"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="scientificName">echo "scientificName <xsl:value-of select="scientificName"/>" &gt;&gt; $@ ;</xsl:if>
	echo "htmlPath	<xsl:apply-templates select="." mode="html"/>" &gt;&gt; $@ ;
	echo "" &gt;&gt; $@ ;
	</xsl:for-each>


<xsl:apply-templates select="genome"/>

<xsl:apply-templates select="accessions/acn"/>

clean:
	rm -f hub.txt genomes.txt ${TMPDIR}

</xsl:template>


<xsl:template match="genome">

###############################################################################

<xsl:value-of select="@id"/>: <xsl:apply-templates select="." mode="bit2"/> <xsl:apply-templates select="." mode="trackDB"/>  <xsl:apply-templates select="." mode="html"/>
	
<xsl:text>
</xsl:text>


<xsl:apply-templates select="." mode="html"/> :  
	mkdir -p $(dir $@)
	echo "&lt;html&gt;&lt;body&gt;TODO: documentation&lt;/body&lt;&gt;/html&gt;" &gt; $@

<xsl:apply-templates select="." mode="bit2"/> :  <xsl:value-of select="fasta"/>
	mkdir -p $(dir $@)
	faToTwoBit -noMask &lt; $@

<xsl:apply-templates select="." mode="blast"/> :  <xsl:value-of select="fasta"/>
	mkdir -p $(dir $@)
	makeblastdb -dbtype nucl -in $&lt;

<xsl:apply-templates select="." mode="trackDB"/>  : <xsl:for-each select="group"> <xsl:apply-templates select="." mode="bb"/> </xsl:for-each>
	mkdir -p $(dir $@)
	rm -f $@
	<xsl:for-each select="group">echo "track <xsl:value-of select="@id"/>" &gt;&gt; $@ ;
	echo "bigDataUrl	<xsl:apply-templates select="." mode="basebb"/>" &gt;&gt; $@ ;
	<xsl:choose>
		<xsl:when test="shortLabel">echo "shortLabel	<xsl:value-of select="shortLabel"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "shortLabel	<xsl:value-of select="translate(@id,'_',' ')"/>" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>
	<xsl:choose>
		<xsl:when test="longLabel">echo "longLabel	<xsl:value-of select="longLabel"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "longLabel	<xsl:value-of select="translate(@id,'_',' ')"/>" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>
	echo "type	bigBed" &gt;&gt; $@ ;
	echo "" &gt;&gt; $@ ;
	</xsl:for-each>

<xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="sizes"/>  : <xsl:value-of select="fasta"/>
	mkdir -p $(dir $@)
	awk 'BEGIN {N=0;S="";} /^>/ {if(N>0) {printf("%s\t%d\n",S,N);N=0;} S=substr($$0,2);next;} {N+=length($$0);} END {printf("%s\t%d\n",S,N); }' &lt; $&lt; &gt; $@
	


<xsl:apply-templates select="group"/>

</xsl:template>


<xsl:template match="group">
<xsl:variable name="fastapath" select="../fasta"/>
<xsl:variable name="includes" select="include"/>
<xsl:variable name="excludes" select="exclude"/>

<xsl:apply-templates select="." mode="bb"/> : <xsl:apply-templates select="." mode="bed"/>  <xsl:apply-templates select="../fasta" mode="sizes"/>
	mkdir -p $(dir $@)
	LC_ALL=C sort -t '	' -k1,1 -k2,2n -k3,3n -k4,4 -u $&lt;  &gt; $@.tmp.bed
	bedToBigBed  $@.tmp.bed <xsl:apply-templates select="../fasta" mode="sizes"/> $@
	rm $@.tmp.bed

<xsl:apply-templates select="." mode="bed"/> : <xsl:apply-templates select="../fasta" mode="blast"/> <xsl:apply-templates select="accessions" mode="dependencies"/>
	rm -f $@<xsl:for-each select="accessions">
	<xsl:variable name="ref" select="@ref"/>
	<xsl:variable name="L" select="/genomeHub/accessions[@id=$ref]"/><xsl:for-each select="$L/acn">
	xsltproc --novalid sequence2fasta.xsl <xsl:apply-templates select="." mode="xml"/> &gt; <xsl:apply-templates select="." mode="fa"/>
	<xsl:text>
	</xsl:text>
	<xsl:choose>
		<xsl:when test="@type='protein' or @source='uniprot'">tblastn</xsl:when>
		<xsl:otherwise>blastn</xsl:otherwise>
	</xsl:choose> -query <xsl:apply-templates select="." mode="fa"/> -db <xsl:value-of select="$fastapath"/> -evalue 1E-3 -outfmt 5 &gt; $@.xml
	rm <xsl:apply-templates select="." mode="fa"/>
	java -jar ../../jvarkit-git/dist/blastmapannots.jar  \
		<xsl:for-each select="$includes"> INCLUDE="<xsl:value-of select="."/>" </xsl:for-each> \
		<xsl:for-each select="$excludes"> EXCLUDE="<xsl:value-of select="."/>" </xsl:for-each> \
		I=<xsl:apply-templates select="." mode="xml"/> \
		B=$@.xml &gt;&gt; $@
	rm $@.xml</xsl:for-each></xsl:for-each>
	
<xsl:text>
</xsl:text>


	
</xsl:template>


<xsl:template match="acn">
<xsl:if test="generate-id(.) = generate-id(key('entries',.))">

<xsl:apply-templates select="." mode="xml"/> : 
	mkdir -p $(dir $@)
	curl ${CURLPROXY} -o $@ <xsl:choose>
		<xsl:when test="@source='uniprot'">"http://www.uniprot.org/uniprot/<xsl:value-of select="."/>.xml"</xsl:when>
		<xsl:when test="@type='dna'">"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&amp;rettype=gb&amp;id=<xsl:value-of select="."/>&amp;retmode=xml"</xsl:when>
		<xsl:otherwise>"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&amp;rettype=gb&amp;id=<xsl:value-of select="."/>&amp;retmode=xml"</xsl:otherwise>
	</xsl:choose>

<xsl:text>
</xsl:text>

<xsl:apply-templates select="." mode="fa"/>:
	mkdir -p $(dir $@)
	curl ${CURLPROXY} -o $@ <xsl:choose>
		<xsl:when test="@source='uniprot'">"http://www.uniprot.org/uniprot/<xsl:value-of select="."/>.fasta"</xsl:when>
		<xsl:when test="@type='dna'">"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&amp;rettype=fasta&amp;id=<xsl:value-of select="."/>"</xsl:when>
		<xsl:otherwise>"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&amp;rettype=fasta&amp;id=<xsl:value-of select="."/>"</xsl:otherwise>
	</xsl:choose>
<xsl:text>
</xsl:text>

<xsl:apply-templates select="." mode="blast"/>: <xsl:apply-templates select="." mode="fa"/>  <xsl:apply-templates select="../../fasta" mode="blast"/>
	mkdir -p $(dir $@)
	
	
</xsl:if>
</xsl:template>

<xsl:template match="accessions" mode="dependencies">
<xsl:variable name="ref" select="@ref"/>
<xsl:variable name="L" select="/genomeHub/accessions[@id=$ref]"/>
<xsl:for-each select="$L/acn"><xsl:apply-templates select="." mode="xml"/> </xsl:for-each>
</xsl:template>

<xsl:template match="acn" mode="xml"><xsl:value-of select="concat('${TMPDIR}/',.,'.xml ')"/></xsl:template>
<xsl:template match="acn" mode="fa"><xsl:value-of select="concat('${TMPDIR}/',.,'.fa ')"/></xsl:template>
<xsl:template match="acn" mode="blast"><xsl:value-of select="concat('${TMPDIR}/',.,'.',../../@id,'.blast.xml ')"/></xsl:template>
<xsl:template match="fasta" mode="blast"><xsl:value-of select="concat('$(addsuffix .nsq,',.,') ')"/></xsl:template>
<xsl:template match="fasta" mode="sizes"><xsl:value-of select="concat('$(dir ',.,')chrom.sizes ')"/></xsl:template>
<xsl:template match="genome" mode="bit2">$(addsuffix .2bit,$(basename <xsl:value-of select="fasta"/>)) </xsl:template>
<xsl:template match="genome" mode="trackDB">$(dir <xsl:value-of select="fasta"/>)trackDb.txt </xsl:template>
<xsl:template match="genome" mode="html">$(dir <xsl:value-of select="fasta"/>)description.html </xsl:template>
<xsl:template match="genome" mode="blast"><xsl:apply-templates select="fasta" mode="blast"/></xsl:template>
<xsl:template match="genome" mode="sizes"><xsl:apply-templates select="fasta" mode="sizes"/></xsl:template>
<xsl:template match="group" mode="basebb"><xsl:value-of select="concat(@id,'.bb ')"/></xsl:template>
<xsl:template match="group" mode="bb">$(dir <xsl:value-of select="../fasta"/>)<xsl:apply-templates select="." mode="basebb"/> </xsl:template>
<xsl:template match="group" mode="bed">$(dir <xsl:value-of select="../fasta"/>)<xsl:value-of select="@id"/>.bed </xsl:template>


</xsl:stylesheet>
