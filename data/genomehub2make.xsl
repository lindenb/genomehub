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
<xsl:key name="entries" match="entry" use="."/>
<xsl:output method="text"  encoding="UTF-8" />

<xsl:template match="/">
<xsl:apply-templates select="genomeHub"/>
</xsl:template>

<xsl:template match="genomeHub">
SHELL=/bin/bash
CURLPROXY= -x proxy-upgrade.univ-nantes.prive:3128 
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
	<xsl:if test="email">echo "email <xsl:value-of select="email"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="description">echo "description <xsl:value-of select="description"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="defaultPos">echo "defaultPos <xsl:value-of select="defaultPos"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="orderKey">echo "defaultPos <xsl:value-of select="orderKey"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="scientificName">echo "scientificName <xsl:value-of select="scientificName"/>" &gt;&gt; $@ ;</xsl:if>
	<xsl:if test="html">echo "htmlPath $(dir <xsl:value-of select="fasta"/>)description.html" &gt;&gt; $@ ;</xsl:if>		
	echo "" &gt;&gt; $@ ;
	</xsl:for-each>


<xsl:apply-templates select="genome"/>

<xsl:apply-templates select="genome/group/entry"/>

clean:
	rm -f hub.txt genomes.txt

</xsl:template>


<xsl:template match="genome">

###############################################################################

<xsl:value-of select="@id"/>: $(addsuffix .2bit,$(basename <xsl:value-of select="fasta"/>)) \
	$(dir <xsl:value-of select="fasta"/>)trackDb.txt


$(addsuffix .2bit,$(basename <xsl:value-of select="fasta"/>)) :  <xsl:value-of select="fasta"/>
	mkdir -p $(dir $@)
	faToTwoBit -noMask &lt; $@

$(addsuffix .nsq,<xsl:value-of select="fasta"/>) :  <xsl:value-of select="fasta"/>
	mkdir -p $(dir $@)
	makeblastdb -dbtype nucl -in &lt;

$(dir <xsl:value-of select="fasta"/>)trackDb.txt : <xsl:for-each select="group"> $(dir <xsl:value-of select="../fasta"/>)<xsl:value-of select="@id"/>.bb </xsl:for-each>
	mkdir -p $(dir $@)
	rm -f $@
	<xsl:for-each select="group">echo "track <xsl:value-of select="@id"/>" &gt;&gt; $@ ;
	echo "bigDataUrl $(dir $@)<xsl:value-of select="@id"/>.bb" &gt;&gt; $@ ;
	<xsl:choose>
		<xsl:when test="shortLabel">echo "shortLabel <xsl:value-of select="shortLabel"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "shortLabel <xsl:value-of select="@id"/>" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>
	<xsl:choose>
		<xsl:when test="longLabel">echo "longLabel <xsl:value-of select="longLabel"/>" &gt;&gt; $@ ;</xsl:when>
		<xsl:otherwise>echo "longLabel <xsl:value-of select="@id"/>" &gt;&gt; $@ ;</xsl:otherwise>
	</xsl:choose>
	echo "type	bigBed" &gt;&gt; $@ ;
	echo "" &gt;&gt; $@ ;
	</xsl:for-each>
	
$(dir <xsl:value-of select="fasta"/>)chrom.sizes: <xsl:value-of select="fasta"/>
	mkdir -p $(dir $@)
	awk 'BEGIN {N=0;S="";} /^>/ {if(N>0) {printf("%s\t%d\n",S,N);N=0;} S=substr($$0,2);next;} {N+=length($$0);} END {printf("%s\t%d\n",S,N); }' &lt; $&lt; &gt; $@
	


<xsl:apply-templates select="group"/>

</xsl:template>


<xsl:template match="group">

$(dir <xsl:value-of select="../fasta"/>)<xsl:value-of select="@id"/>.bb : $(dir <xsl:value-of select="../fasta"/>)<xsl:value-of select="@id"/>.bed $(dir <xsl:value-of select="../fasta"/>)chrom.sizes
	mkdir -p $(dir $@)
	LC_ALL=C sort -t '	' -k1,1 -k2,2n -k3,3n $&lt; | uniq &gt; $@.tmp.bed
	bedToBigBed  $@.tmp.bed $(dir <xsl:value-of select="../fasta"/>)chrom.sizes $@
	rm $@.tmp.bed

$(dir <xsl:value-of select="../fasta"/>)<xsl:value-of select="@id"/>.bed : $(addsuffix .nsq,<xsl:value-of select="../fasta"/>) <xsl:for-each select="entry"> tmp/<xsl:value-of select="."/>.fa tmp/<xsl:value-of select="."/>.xml </xsl:for-each>
	rm -f $@
	<xsl:for-each select="entry">
	<xsl:choose><xsl:when test="@type='protein' or @source='uniprot'">tblastn</xsl:when><xsl:otherwise>blastn</xsl:otherwise></xsl:choose> -query tmp/<xsl:value-of select="."/>.fa -db <xsl:value-of select="../../fasta"/> -evalue 1E-3 -outfmt 5 &gt; $@.blast.xml 
	java -cp ../../jsandbox/dist/mapblastannot.jar sandbox.MapBlastAnnotation <xsl:for-each select="../filter"> -F <xsl:value-of select="."/> </xsl:for-each> tmp/<xsl:value-of select="."/>.xml   $@.blast.xml &gt;&gt; $@
	</xsl:for-each>
	rm  $@.blast.xml

	
</xsl:template>


<xsl:template match="entry">
<xsl:if test="generate-id(.) = generate-id(key('entries',.))">

tmp/<xsl:value-of select="."/>.xml : 
	mkdir -p $(dir $@)
	curl ${CURLPROXY} -o $@ <xsl:choose>
		<xsl:when test="@source='uniprot'">"http://www.uniprot.org/uniprot/<xsl:value-of select="."/>.xml"</xsl:when>
		<xsl:when test="@type='dna'">"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&amp;rettype=gb&amp;id=<xsl:value-of select="."/>&amp;retmode=xml"</xsl:when>
		<xsl:otherwise>"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&amp;rettype=gb&amp;id=<xsl:value-of select="."/>&amp;retmode=xml"</xsl:otherwise>
	</xsl:choose>
	

tmp/<xsl:value-of select="."/>.fa:
	mkdir -p $(dir $@)
	curl ${CURLPROXY} -o $@ <xsl:choose>
		<xsl:when test="@source='uniprot'">"http://www.uniprot.org/uniprot/<xsl:value-of select="."/>.fasta"</xsl:when>
		<xsl:when test="@type='dna'">"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&amp;rettype=fasta&amp;id=<xsl:value-of select="."/>"</xsl:when>
		<xsl:otherwise>"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&amp;rettype=fasta&amp;id=<xsl:value-of select="."/>"</xsl:otherwise>
	</xsl:choose>
		
</xsl:if>
</xsl:template>


</xsl:stylesheet>
