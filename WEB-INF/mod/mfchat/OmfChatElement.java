//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header: /cvsrepo/PRM/WEB-INF/classes/mod/mfchat/OmfChatElement.java,v 1.1 2006/10/06 23:54:18 edwardc Exp $
//
//	File:	$RCSfile: OmfChatElement.java,v $
//	Author:	ECC
//	Date:	$Date: 2006/10/06 23:54:18 $
//  Description:
//      Implement chat element in queue for OMF. 
//
//	Modification:
/////////////////////////////////////////////////////////////////////

package mod.mfchat;

public class OmfChatElement {
	private int m_offset;
	private int m_length;
	
	public OmfChatElement(int offset, int length)
	{
		m_offset = offset;
		m_length = length;
	}
	
	public int getOffset() {return m_offset;}
	public int getLength() {return m_length;}
	
	public void setOffset(int offset) {m_offset = offset;}
	public void setLength(int length) {m_length = length;}
}
