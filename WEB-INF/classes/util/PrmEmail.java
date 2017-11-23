//
//  Copyright (c) 2002, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   Email.java
//  Author:
//  Date:   05.30.2002
//  Description:
//
//  Modification:
//
//			@AGQ080306	Handled servers that needs to authenticate
//			@ECC050307a	Support SMTP set up with no relay email.  Must allow pst FROM to send email.
//
/////////////////////////////////////////////////////////////////////
//
// Email.java : implementation of the Email class
//

package util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Date;
import java.util.Properties;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.mail.Address;
import javax.mail.Authenticator;
import javax.mail.BodyPart;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.Part;
import javax.mail.PasswordAuthentication;
import javax.mail.SendFailedException;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;

import org.apache.log4j.Logger;

public class PrmEmail
{
	private String m_host = null;
	private String m_port = null;
	private String m_admin = null;
	private boolean m_testMail = false;
	private boolean m_noMail = false;
	private String m_bcc = null;
	private String m_path = null;
	private boolean m_noRelayMail = false;	// @ECC050307a
	private String m_from = null;
	
	private static user jwu;
	private static userManager uMgr;
	static Logger l = PrmLog.getLog();
	private static final String M_AUTH_USER, M_AUTH_PASS, M_SYS_USER, 
			M_SYS_PASS, M_SYS_HOST, M_SYS_TYPE;
	
	private static final String LOCALHOST = Util.getPropKey("pst", "LOCALHOST");

	static {
		M_AUTH_USER = Util.getPropKey("pst", "MAIL_USER"); 		// sent email user
		String s = Util.getPropKey("pst", "MAIL_PASS"); 		// sent email pass
		M_AUTH_PASS = (s!=null)?s:"";
		M_SYS_HOST = Util.getPropKey("pst", "MAIL_SYS_HOST"); 	// receive mail host
		M_SYS_USER = Util.getPropKey("pst", "MAIL_SYS_USER"); 	// receive mail user
		s = Util.getPropKey("pst", "MAIL_SYS_PASS"); 			// receive mail pass
		M_SYS_PASS = (s!=null)?s:"";
		s = Util.getPropKey("pst", "MAIL_SYS_TYPE"); 			// imap or pop3
		M_SYS_TYPE = (s!=null)?s:"pop3";
		
		try {
			jwu = Prm.getSpecialUser();
			uMgr = userManager.getInstance();
		}
		catch (PmpException e) {}
	}	
	
	public PrmEmail()
	{
		String s;
		m_host = Util.getPropKey("pst", "MAILHOST");
		m_port = Util.getPropKey("pst", "MAILPORT");
		m_admin = Util.getPropKey("pst", "MAIL_ADMIN");
		m_bcc = Util.getPropKey("pst", "BCC");
		m_path = Util.getPropKey("pst", "MAIL_FILEPATH");
		m_from = Util.getPropKey("pst", "FROM");			// @ECC050307a

		if((s = Util.getPropKey("pst", "MAIL_TEST")) != null && s.equalsIgnoreCase("true"))
			m_testMail = true;
		else
			m_testMail = false;

		if((s = Util.getPropKey("pst", "MAIL_NO_SEND")) != null && s.equalsIgnoreCase("true"))
			m_noMail = true;
		else
			m_noMail = false;
		
		if ((s = Util.getPropKey("pst", "MAIL_NO_RELAY")) != null && s.equalsIgnoreCase("true"))
			m_noRelayMail = true;

	}

	public void setHost(String host)
	{
		m_host = host;
	}

	public void setAdmin(String admin)
	{
		m_admin = admin;
	}

	public String getAdmin()
	{
		return m_admin;
	}

	public String getPath()
	{
		return m_path;
	}

	public boolean isTestMail()
	{
		return m_testMail;
	}

	public void setTestMail(boolean flag)
	{
		m_testMail = flag;
	}

	public boolean isNoMail()
	{
		return m_noMail;
	}

	public void setNoMail(boolean flag)
	{
		m_noMail = flag;
	}

	public void sendMail(String to, String from, String subject, String msgText, String fileName)
	{
		sendMail(to, from, null, null, subject, msgText, fileName, false, null);
	}

	// also called by post_memo.jsp to create a display in email format
	public static String insertFileContent(String filePathName, String msgText)
	throws Exception
	{
		BufferedReader is = null;
		String mailContentBuffer = new String();
		try
		{
			//fileName = m_path + "/" + fileName;
			File readInFile = new File(filePathName);
			is = new BufferedReader(new FileReader(readInFile));
			String line;				// hold the line of read in file

			while ((line = is.readLine()) != null)
			{
				if (line.startsWith("$MessageBody$"))
					mailContentBuffer += msgText +"\n";
				else
					mailContentBuffer += line + "\n";
			}
		}
		catch (Exception e)
		{
			System.out.println( "Exception in PrmEmail.java: " + e.toString() );
			throw e;
		}
		is.close();
		return mailContentBuffer;
	}

	public void sendMail(String to, String from, String cc, String bcc, String subject,
		String msgText, String fileName, boolean bHidden, DataSource [] dsArr)
	{
		sendMail(to, from, cc, bcc, subject, msgText, fileName, bHidden, dsArr, "text/html;charset=UTF-8");
	}

	public void sendMail(String to, String from, String cc, String bcc, String subject,
		String msgText, String fileName, boolean bHidden, DataSource [] dsArr, String contentType)
	{
		// create some properties and get the default Session
		if(!m_noMail) 
		{
			Properties props = System.getProperties();
			props.put("mail.smtp.host", m_host);
			if (LOCALHOST != null)
				props.put("mail.smtp.localhost", LOCALHOST);
			
			if (!StringUtil.isNullOrEmptyString(m_port)) props.put("mail.smtp.port", m_port);
			
			// @AGQ080306 added for authen
			Authenticator auth = null;
			String mailAuthen = Util.getPropKey("pst", "MAIL_AUTHEN");
			if (mailAuthen != null && mailAuthen.equalsIgnoreCase("true")) {
				if (new SMTPAuthenticator().getPasswordAuthentication() != null) {
					props.put("mail.smtp.auth", "true");
					String startTLS = Util.getPropKey("pst", "MAIL_STARTTLS");
					if (startTLS != null && startTLS.equalsIgnoreCase("true")) {
						props.put("mail.smtp.starttls.enable", "true");
					}
					props.put("mail.transport.protocol", "smtp");
					auth = new SMTPAuthenticator();		// this fills username/password from pst
				}
			}
			// Session session = Session.getDefaultInstance(props, null);
			javax.mail.Session mailsess = javax.mail.Session.getDefaultInstance(props, auth);
			
			if (Util.isNullOrEmptyString(contentType)) {
				contentType = "text/html;charset=UTF-8";	// "text/html";
			}

			Message msg = null;
			try
			{
				// create a message
				//Message msg = new MimeMessage(session);
				msg = new MimeMessage(mailsess);
				
				// @ECC050307a
				if (m_noRelayMail && m_from!=null)
					from = m_from;
				
				msg.setFrom(new InternetAddress(from));
				msg.setSubject(subject);
				msg.setSentDate(new Date());

				// incorporate file
				if (fileName != null)
				{
					String fullFileName = m_path + "/" + fileName;
					msgText = insertFileContent(fullFileName, msgText);
				}

				
				// handle attachments
				if (dsArr!=null && dsArr.length>0)
				{
					// create the msg text
					BodyPart messageBodyPart = new MimeBodyPart();
					messageBodyPart.setContent(msgText, contentType);
					
					// ready to create multipart and insert the images
					MimeMultipart multipart = new MimeMultipart("related");
					multipart.addBodyPart(messageBodyPart);		// first insert the text into the multipart

					for (int i=0; i<dsArr.length; i++)
					{
						if (dsArr[i] == null) break;
						messageBodyPart = new MimeBodyPart();
						messageBodyPart.setDataHandler(new DataHandler(dsArr[i]));
						messageBodyPart.setHeader("Content-ID","<prm_img" + i + ">");
						multipart.addBodyPart(messageBodyPart);	// insert the images into the multipart
					}
					// Associate multi-part with message
					msg.setContent(multipart);
				}
				else
					msg.setContent(msgText, contentType);

				msg.setHeader("X-Mailer", "msgsend");
				msg.setSentDate(new Date());

				InternetAddress[] address;
				String [] sa = to.split(" ");
				if (bHidden || sa.length>=50)
				{
					// ignore what is in bcc now
					l.info("Switched email list to bcc. Total = " + sa.length);
					bcc = to;
					to = m_from;
				}

				boolean bNeedSend = false;
				if(m_testMail)
				{
					//msg.setFrom(new InternetAddress(m_admin));
					address = new InternetAddress[1];
					address[0] = new InternetAddress(m_admin);
					msg.setRecipients(Message.RecipientType.TO, address);
					bNeedSend = true;
					l.info("PrmEmail thread send TEST mail: " + subject);
					l.info("   FROM [" + from + "]");
					l.info("   TO   [" +to+ "] (test email only to admin)");					
				}
				else
				{
					String [] st = to.trim().split(" |,|;");
					int stCount = st.length;
					l.info("PrmEmail.java send mail: " + subject);
					l.info("   FROM [" + from + "]");
					l.info("   TO   [" +to+ "]");					
					address = new InternetAddress[stCount];
					for (int i=0; i < stCount; i++)
					{
						if (StringUtil.isNullOrEmptyString(st[i])) continue;
						address[i] = new InternetAddress(st[i]);
						bNeedSend = true;
						//msg.setRecipient(Message.RecipientType.TO, address[i]);
						//Transport.send(msg);
					}
					msg.setRecipients(Message.RecipientType.TO, address);

					// only put cc and bcc if there is not testing.
					if (!StringUtil.isNullOrEmptyString(cc))
					{
						l.info("   CC   [" + cc + "]");
						st = cc.split(" |,|;");
						convertEmailAddress(st);
						stCount = st.length;
						InternetAddress[] ccaddress = new InternetAddress[stCount];
						for (int i=0; i < stCount; i++)
						{
							if (StringUtil.isNullOrEmptyString(st[i])) continue;
							ccaddress[i] = new InternetAddress(st[i]);
							bNeedSend = true;
							//msg.setRecipient(Message.RecipientType.CC, ccaddress[i]);
							//Transport.send(msg);
						}
						msg.setRecipients(Message.RecipientType.CC, ccaddress);
					}

					//if (bcc == null) bcc = m_bcc;
					if (!StringUtil.isNullOrEmptyString(bcc))
					{
						bcc = bcc.trim();
						l.info("   BCC  [" +bcc+ "]");
						st = bcc.split(" |,|;");
						convertEmailAddress(st);
						stCount = st.length;
						InternetAddress[] bccaddress = new InternetAddress[stCount];					
						for (int i=0; i < stCount; i++)
						{
							if (StringUtil.isNullOrEmptyString(st[i])) continue;
							bccaddress[i] = new InternetAddress(st[i]);
							bNeedSend = true;
							//msg.setRecipient(Message.RecipientType.BCC, bccaddress[i]);
							//Transport.send(msg);
						}
						msg.setRecipients(Message.RecipientType.BCC, bccaddress);
					}
				}
				if (bNeedSend)
				{
					Transport.send(msg);	/////////// SENDING OUT THE EMAIL NOW
				}
			}
			catch (Exception mex)
			{
				System.out.println("\n--Exception handling in Email.java");
				System.out.println(mex.getMessage() + "\n");
				//mex.printStackTrace();
				
				Exception ex = mex;

				do
				{
					if (ex instanceof SendFailedException)
					{
						SendFailedException sfex = (SendFailedException)ex;
						Address[] invalid = sfex.getInvalidAddresses();
						if (invalid != null)
						{
							System.out.println("    ** Invalid Addresses");
							if (invalid != null)
							{
								for (int i = 0; i < invalid.length; i++)
								System.out.println("         " + invalid[i]);
							}
						}

						Address[] validUnsent = sfex.getValidUnsentAddresses();
						if (validUnsent != null)
						{
							System.out.println("    ** Valid Unsent Addresses: try sending again");
							if (validUnsent != null) {
								for (int i = 0; i < validUnsent.length; i++)
								System.out.println("         "+validUnsent[i]);
							}
							
							// resends email to validUnsent
							try {
								msg.setRecipients(Message.RecipientType.TO, validUnsent);
								l.info("Resends email to validUnsent list.");
							}
							catch (Exception e) {
								System.out.println("*** Failed to resend to validUnsent list");
							}
						}

						Address[] validSent = sfex.getValidSentAddresses();
						if (validSent != null)
						{
							System.out.println("    ** Valid Sent Addresses");
							if (validSent != null)
							{
								for (int i = 0; i < validSent.length; i++)
								System.out.println("         "+validSent[i]);
							}
						}
					}

					if (ex instanceof MessagingException)
						ex = ((MessagingException)ex).getNextException();
					else
						ex = null;
				} while (ex != null);
			}
		} // if send
		else
		{
			// dump a statement
			Logger l = PrmLog.getLog();
			l.info("Send Email (no send):");
			l.info("  from = " + from);
			l.info("  to   = " + to);
			l.info("  cc   = " + cc);
			l.info("  bcc  = " + bcc);
			l.info("  Subj = " + subject);
			l.info("  content:");
			l.info("[" + msgText + "]");
		}
	}
	
	private void convertEmailAddress(String[] st) {
		// convert userId or username to email address
		if (st == null) return;
		
		String s;
		boolean isUserId;
		PstAbstractObject u;
		int uid = 0;
		
		for (int i=0; i<st.length; i++) {
			s = st[i];
			if (s.indexOf('@') != -1)
				continue;

			// check if it is userId
			isUserId = true;
			try {uid = Integer.parseInt(s);}
			catch (NumberFormatException e) {isUserId = false;}

			try {
				if (isUserId)
					u = uMgr.get(jwu, uid);
				else
					u = uMgr.get(jwu, s);	// it is in username format
				
				st[i] = u.getStringAttribute("Email");
			}
			catch (PmpException e) {continue;}
		}
		
	}

	// @AGQ080306
	/**
	 * Retrieves stored passwords from pst.properties for mail authentication
	 */
	private class SMTPAuthenticator extends javax.mail.Authenticator
	{
	    public PasswordAuthentication getPasswordAuthentication()
	    {
	    	if (M_AUTH_USER == null)
	    		return null;
	    	return new PasswordAuthentication(M_AUTH_USER, M_AUTH_PASS);
	    }
	}
	
	/**
	 * Receives the email using the default settings in pst.properties
	 *
	 */
	public static void receiveMail() {
		receiveMail(null, null, null);
	}
	
	// @AGQ080806
	/**
	 * Checks email 
	 * @param popServer
	 * @param popUser
	 * @param popPassword
	 */
	public static void receiveMail(String popServer, String popUser, String popPassword) {
	
	    Store store=null;
	    Folder folder=null;
	    
	    if (popServer==null) popServer = M_SYS_HOST;
	    if (popUser==null) popUser = M_SYS_USER;
	    if (popPassword==null) popPassword = M_SYS_PASS;
	    
	    try
	    {
	      // -- Get hold of the default session --
	      Properties props = System.getProperties();
	      Session session = Session.getDefaultInstance(props, null);

	      // -- Get hold of a POP3 message store, and connect to it --
	      store = session.getStore(M_SYS_TYPE);
	      store.connect(popServer, popUser, popPassword);
	      
	      // -- Try to get hold of the default folder --
	      folder = store.getDefaultFolder();
	      if (folder == null) throw new Exception("No default folder");

	      // -- ...and its INBOX --
	      folder = folder.getFolder("INBOX");
	      if (folder == null) throw new Exception("No POP3 INBOX");

	      // -- Open the folder for read only --
	      folder.open(Folder.READ_ONLY);

	      // -- Get the message wrappers and process them --
	      Message[] msgs = folder.getMessages();
	      int max = msgs.length;
	      if (max > 10) max = 10;
	      for (int msgNum = 0; msgNum < max; msgNum++)
	      {
	        printMessage(msgs[msgNum]);
	      }

	    }
	    catch (Exception ex)
	    {
	      ex.printStackTrace();
	    }
	    finally
	    {
	      // -- Close down nicely --
	      try
	      {
	        if (folder!=null) folder.close(false);
	        if (store!=null) store.close();
	      }
	      catch (Exception ex2) {ex2.printStackTrace();}
	    }
	  }
	
	  /**
	    * "printMessage()" method to print a message.
	    */
	  public static void printMessage(Message message)
	  {
	    try
	    {
	      // Get the header information
	      String from=((InternetAddress)message.getFrom()[0]).getPersonal();
	      if (from==null) from=((InternetAddress)message.getFrom()[0]).getAddress();
	      System.out.println("FROM: "+from);

	      String subject=message.getSubject();
	      System.out.println("SUBJECT: "+subject);

	      // -- Get the message part (i.e. the message itself) --
	      Part messagePart=message;
	      Object content=messagePart.getContent();

	      // -- or its first body part if it is a multipart message --
	      if (content instanceof Multipart)
	      {
	        messagePart=((Multipart)content).getBodyPart(0);
	        System.out.println("[ Multipart Message ]");
	      }

	      // -- Get the content type --
	      String contentType=messagePart.getContentType();

	      // -- If the content is plain text, we can print it --
	      System.out.println("CONTENT:"+contentType);

	      if (contentType.startsWith("text/plain")
	       || contentType.startsWith("text/html")
	       || contentType.startsWith("TEXT/PLAIN")
	       || contentType.startsWith("TEXT/HTML"))
	      {
	        InputStream is = messagePart.getInputStream();

	        BufferedReader reader
	         =new BufferedReader(new InputStreamReader(is));
	        String thisLine=reader.readLine();

	        while (thisLine!=null)
	        {
	          System.out.println(thisLine);
	          thisLine=reader.readLine();
	        }
	      }

	      System.out.println("-----------------------------");
	    }
	    catch (Exception ex)
	    {
	      ex.printStackTrace();
	    }
	  }
	  
	public void sendMtgReq(String to, String from, String cc, String bcc, String subject,
		String calBufTxt, boolean bHidden)
	{
		// send outlook meeting request
		if(!m_noMail) //!m_noMail
		{
			Properties props = System.getProperties();
			props.put("mail.smtp.host", m_host);
			if (!StringUtil.isNullOrEmptyString(m_port)) props.put("mail.smtp.port", m_port);
			
			// If the SMTP server CPM is using requires authentication of username/password
			// then we need to add that to pst.properties. Login as that user (e.g. cpm) to
			// authenticate for relay (or not)
			Authenticator auth = null;
			String mailAuthen = Util.getPropKey("pst", "MAIL_AUTHEN");
			if (mailAuthen != null && mailAuthen.equalsIgnoreCase("true")) {
				if (new SMTPAuthenticator().getPasswordAuthentication() != null) {
					props.put("mail.smtp.auth", "true");
					props.put("mail.transport.protocol", "smtp");
					auth = new SMTPAuthenticator();
					l.info("Email Properties SMTP authentication for: " + M_AUTH_USER);
				}
			}

			SecurityManager security = System.getSecurityManager();		
			Session mailsess;
			if (security == null) {
				mailsess = Session.getInstance(props, auth);
			}
			else
				mailsess = Session.getDefaultInstance(props, auth);

			try
			{
				// create a message
				//Message msg = new MimeMessage(session);
				Message msg = new MimeMessage(mailsess);
				
				// @ECC050307a
				if (m_noRelayMail && m_from!=null)
					from = m_from;
				
				msg.setFrom(new InternetAddress(from));
				msg.setSubject(subject);
				msg.setSentDate(new Date());
				//msg.setHeader("X-Mailer", "msgsend");
				msg.setHeader("Content-Class", "urn:content-classes:calendarmessage");
				msg.setHeader("Content-ID","calendar_message");
				msg.addHeader("method", "REQUEST");
				msg.addHeader("charset", "UTF-8");
				msg.addHeader("component", "vevent");
				msg.setContent(calBufTxt, "text/calendar");		

				if (bHidden)
				{
					// ignore what is in bcc now
					bcc = to;
					to = "Info@egiomm.com";
				}
				setRecipients(msg, to, cc, bcc);
				Transport.send(msg);
				l.info("Email sendMtgReq() by [" + from + "] complete.");
			}
			catch (Exception ex)
			{
				System.out.println("\n--Exception handling in Email.java sendMtgReq()");
				ex.printStackTrace();
			}
		}
		else
		{
			System.out.println("Send Meeting Request:");
			System.out.println("  from = " + from);
			System.out.println("  to   = " + to);
			System.out.println("  Subj = " + subject);
		}
	}
			
	private void setRecipients(Message msg, String to, String cc, String bcc)
		throws Exception
	{
		String [] st = to.split(" |,|;");
		convertEmailAddress(st);
		int stCount = st.length;
		InternetAddress [] address = new InternetAddress[stCount];
		for (int i=0; i < stCount; i++)
		{
			if (StringUtil.isNullOrEmptyString(st[i])) continue;
			address[i] = new InternetAddress(st[i]);
		}
		msg.setRecipients(Message.RecipientType.TO, address);
	
		// only put cc and bcc if there is not testing.
		if (cc != null)
		{
			st = cc.split(" |,|;");
			convertEmailAddress(st);
			stCount = st.length;
			InternetAddress[] ccaddress = new InternetAddress[stCount];
			for (int i=0; i < stCount; i++)
			{
				if (StringUtil.isNullOrEmptyString(st[i])) continue;
				ccaddress[i] = new InternetAddress(st[i]);
			}
			msg.setRecipients(Message.RecipientType.CC, ccaddress);
		}
		
		if (bcc == null) bcc = m_bcc;
		if (bcc != null)
			bcc = bcc.trim();
		if (bcc.length() > 0)
		{
			st = bcc.split(" |,|;");
			convertEmailAddress(st);
			stCount = st.length;
			InternetAddress[] bccaddress = new InternetAddress[stCount];					
			for (int i=0; i < stCount; i++)
			{
				if (StringUtil.isNullOrEmptyString(st[i])) continue;
				bccaddress[i] = new InternetAddress(st[i]);
			}
			msg.setRecipients(Message.RecipientType.BCC, bccaddress);
		}
	}	// END: setRecipients()	  
}


