package com.github.lindenb.genomehub;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.bind.JAXBContext;
import javax.xml.transform.stream.StreamSource;

import gov.nih.nlm.ncbi.blast.*;
import org.uniprot.uniprot.*;

public class GenomeHubGenerator
	{
	private static Logger LOG=Logger.getLogger("genomehub");
	private javax.xml.bind.Marshaller marshaller;
	private javax.xml.bind.Unmarshaller unmarshaller;
	private GenomeHubGenerator() throws Exception
		{
		JAXBContext jaxbCtxt=JAXBContext.newInstance(
			  	"java/com/github/lindenb/genomehub:"+
				"gov.nih.nlm.ncbi/blast:"+
			  	"org.uniprot.uniprot"
			  	);
		this.marshaller=jaxbCtxt.createMarshaller();
		this.unmarshaller=jaxbCtxt.createUnmarshaller();

		}
	private void exec(List<String> args) throws Exception
		{
		
		}
	
	private void faToTwoBit()
		{
		
		}
	private void blastx()
	{
		Process proc=Runtime.getRuntime().exec(
				new String[]{
						"blastn",
						"-query",f1.toString(),
						"-db",fasta(st),
						"-outfmt","5",
						"-out","-"
					}
				);
	}
	private void makeblastdb(Genome g) throws Exception
		{
		LOG.info("makeblastdb for "+g.getId());
		String args[]=new String[]{
				"makeblastdb",
				"-dbtype","nucl",
				"-in",g.getFasta()
				};
		Process proc=Runtime.getRuntime().exec(args);
		int ret0=proc.waitFor();
		if(ret0!=0)
			{
			LOG.severe("error formatdb:"+Arrays.asList(args));
			System.exit(-1);
			}

		}
	private void make(Genome g) throws Exception
		{
		faToTwoBit();
		makeblastdb(g);
		}
	
	private void run(String[] args) throws Exception
		{
		int optind=0;
		while(optind<args.length)
			{
			if(args[optind].equals("-h"))
				{
				return;
				}
			else if(args[optind].equals("-L"))
				{
				
				}
			else if(args[optind].equals("--"))
				{
				optind++;
				break;
				}
			else if(args[optind].startsWith("-"))
				{
				System.err.println("Unnown option: "+args[optind]);
				return;
				}
			else
				{
				break;
				}
			++optind;
			}
		if(optind+1!=args.length)
			{
			LOG.severe("expected only one parameter");
			System.exit(-1);
			}
		LOG.info("reading "+args[optind]);
		GenomeHub config=this.unmarshaller.unmarshal(new StreamSource( new File(args[optind])),GenomeHub.class).getValue();
		for(Genome g:config.getGenome())
			{
			make(g);
			}
		}

	
	public static void main(String[] args) throws Exception
		{
		new GenomeHubGenerator().run(args);
		}
	}
