package mod.se.filehandler;

import java.io.File;
import java.io.IOException;

import org.apache.html.dom.HTMLDocumentImpl;
import org.cyberneko.html.parsers.DOMFragmentParser;
import org.w3c.dom.DocumentFragment;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

public class HandlerHTML extends Handler {
	private DOMFragmentParser parser = new DOMFragmentParser();
	
	public HandlerHTML(String fileLocation) {
		super(fileLocation);
	}
	
	public boolean extractInfo() {
		File file = new File(getFileLocation());
		if (file.exists() && file.canRead() && !file.isDirectory()) {
			DocumentFragment node = new HTMLDocumentImpl().createDocumentFragment();
			String fileLocation = getFileLocation();
			try {
			  parser.parse(new InputSource(fileLocation), node);
			}
			catch (IOException e) {
			  l.error(e);
			  return super.extractInfo();
			}
			catch (SAXException e) {
			  l.error(e);
			  return super.extractInfo();
			}
			catch (Exception e) {
				l.error(e);
				return super.extractInfo();
			}
	
			StringBuffer sb = new StringBuffer();
			getText(sb, node, "title");
			
			sb.setLength(0);
			getText(sb, node);
			String text = sb.toString();
			setContents(text);
			return true;
		}
		else
			return false;
	}

	  private void getText(StringBuffer sb, Node node) {
	    if (node.getNodeType() == Node.TEXT_NODE) {
	      sb.append(node.getNodeValue());
	    }
	    NodeList children = node.getChildNodes();
	    if (children != null) {
	      int len = children.getLength();
	      for (int i = 0; i < len; i++) {
	        getText(sb, children.item(i));
	      }
	    }
	  }
	
	  private boolean getText(StringBuffer sb, Node node,
	    String element) {
	    if (node.getNodeType() == Node.ELEMENT_NODE) {
	      if (element.equalsIgnoreCase(node.getNodeName())) {
	        getText(sb, node);
	        return true;
	      }
	    }
	    NodeList children = node.getChildNodes();
	    if (children != null) {
	      int len = children.getLength();
	      for (int i = 0; i < len; i++) {
	        if (getText(sb, children.item(i), element)) {
	          return true;
	        }
	      }
	    }
	    return false;
	  }
}
