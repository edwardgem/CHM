//
//  Copyright (c) 2002, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   EmailThread.java
//  Author: Johnny Lo
//  Date:   11.06.2003
//  Description:
//
//  Modification:
//
//
/////////////////////////////////////////////////////////////////////
//
// EmailThread.java : implementation of the EmailThread class
//

package util;

import javax.activation.DataSource;

public class EmailThread extends Thread
{

	Object [] m_to;
	DataSource [] m_dsArr;

	String m_from, m_cc, m_bcc, m_subject, m_msgText, m_fileName, m_contentType;
	boolean m_hidden;

	public EmailThread(String threadName, Object[] to, String from,
			String cc, String bcc, String subject, String msgText, String fileName, boolean bHidden, DataSource [] dsArr)
	{
		this(threadName, to, from, cc, bcc, subject, msgText, fileName, bHidden);
		m_dsArr = dsArr;
	}
	
	public EmailThread(String threadName, Object[] to, String from,
		String cc, String bcc, String subject, String msgText, String fileName, boolean bHidden)
	{
		super(threadName);
		m_to = to;
		m_from = from;
		m_cc = cc;
		m_bcc = bcc;
		m_subject = subject;
		m_msgText = msgText;
		m_fileName = fileName;
		m_hidden = bHidden;
		m_contentType = "";
	}

	public EmailThread(String threadName, Object[] to, String from,
		String cc, String bcc, String subject, String msgText, String fileName)
	{
		this(threadName, to, from, cc, bcc, subject, msgText, fileName, false);
	}
	
	public void setContentType(String contentType)
	{
		m_contentType = contentType;
	}

	public void run()
		throws IllegalStateException
	{
		PrmEmail email = new PrmEmail();
		//email.setTestMail(true);

		if ((m_to == null) || (m_to.length == 0))
			throw new IllegalStateException("To address array cannot be empty");

		String toAddresses = "";
		for(int i = 0; i < m_to.length; i++)
		{
			//System.out.println("Email Thread: " + m_to.get(i));
			toAddresses += (String)m_to[i] + " ";
		}
		email.sendMail(toAddresses, m_from, m_cc, m_bcc, m_subject, m_msgText,
				m_fileName, m_hidden, m_dsArr, m_contentType);
	}
}
