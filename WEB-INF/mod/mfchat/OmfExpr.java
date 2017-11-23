//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header: /cvsrepo/PRM/WEB-INF/classes/mod/mfchat/OmfExpr.java,v 1.1 2006/10/02 17:00:44 edwardc Exp $
//
//	File:	$RCSfile: OmfExpr.java,v $
//	Author:	ECC
//	Date:	$Date: 2006/10/02 17:00:44 $
//  Description:
//      Implement expression for OMF. 
//
//	Modification:
/////////////////////////////////////////////////////////////////////

package mod.mfchat;

public class OmfExpr {
	private String m_id;
	private String m_str;
	
	public OmfExpr(String id, String str)
	{
		m_id = id;
		m_str = str;
	}
	
	public String getId() {return m_id;}
	public String getStr() {return m_str;}
	
	public void setId(String id) {m_id = id;}
	public void setStr(String str) {m_str = str;}
}
