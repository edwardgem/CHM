/** an example sink for content events.   It simply prints what it sees. */
package util;

import java.util.HashMap;

public class XHandle extends org.xml.sax.helpers.DefaultHandler
	implements org.xml.sax.ContentHandler
{
	String m_propValue;
	HashMap m_hash;

	public HashMap newHash()
	{
		m_hash = new HashMap();
		return m_hash;
	}

	final private static void print(final String context, final String text)
	{
		System.out.println( context + ": " + text);
	}

	final public void startElement(final String namespace, final String localname, final String type, final org.xml.sax.Attributes attributes )
		throws org.xml.sax.SAXException
	{
		//print( "startElement", type );
	}

	final public void endElement( final String namespace, final String localname, final String type)
		throws org.xml.sax.SAXException
	{
		//print( "endElement  ", type );
		if (m_propValue != null)
		{
			m_hash.put(type, m_propValue);
			m_propValue = null;
		}
	}

	final public void characters( final char[] ch, final int start, final int len )
	{
		String text = new String( ch, start, len );
		text = text.trim();
		m_propValue = text;
	}
}
