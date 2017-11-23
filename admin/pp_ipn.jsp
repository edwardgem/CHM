<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	pp_ipn.jsp
//	Author:	ECC
//	Date:	09/17/08
//	Description:
//		PayPal IPN callback page.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.pst.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.io.*" %>
<%@ page import = "util.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	// PayPal IPN event call page
	// code from PayPal code sample
	final String FROM = Util.getPropKey("pst", "FROM");
	final String MAILFILE = "alert.htm";

	final String PAYPAL_URL	= "https://www.paypal.com/cgi-bin/webscr";
	//final String PAYPAL_URL = "https://www.sandbox.paypal.com/cgi-bin/webscr";
	Logger l = PrmLog.getLog();

	// read post from PayPal system and add 'cmd'
	Enumeration en = request.getParameterNames();
	String str = "cmd=_notify-validate";
	while(en.hasMoreElements())
	{
		String paramName = (String)en.nextElement();
		String paramValue = request.getParameter(paramName);
		str = str + "&" + paramName + "=" + URLEncoder.encode(paramValue);
	}
	
	// post back to PayPal system to validate
	// NOTE: change http: to https: in the following URL to verify using SSL (for increased security).
	// using HTTPS requires either Java 1.4 or greater, or Java Secure Socket Extension (JSSE)
	// and configured for older versions.
	URL u = new URL(PAYPAL_URL);
	URLConnection uc = u.openConnection();
	uc.setDoOutput(true);
	uc.setRequestProperty("Content-Type","application/x-www-form-urlencoded");
	PrintWriter pw = new PrintWriter(uc.getOutputStream());
	pw.println(str);
	pw.close();
	
	BufferedReader in = new BufferedReader(
	new InputStreamReader(uc.getInputStream()));
	String res = in.readLine();
	in.close();
	
	// assign posted variables to local variables
	String itemName = request.getParameter("item_name");
	String itemNumber = request.getParameter("item_number");
	String paymentStatus = request.getParameter("payment_status");
	String paymentAmount = request.getParameter("mc_gross");
	String paymentCurrency = request.getParameter("mc_currency");
	String txnId = request.getParameter("txn_id");
	String receiverEmail = request.getParameter("receiver_email");
	String payerEmail = request.getParameter("payer_email");
	
	//check notification validation
	l.info("----- Received PayPal IPN -----");
	if(res.equals("VERIFIED"))
	{
		// check that paymentStatus=Completed
		// check that txnId has not been previously processed
		// check that receiverEmail is your Primary PayPal email
		// check that paymentAmount/paymentCurrency are correct
		// process payment
		l.info("Status: " + res + "\n" +
				"txnId           = " + txnId + "\n" +
				"itemName        = " + itemName + "\n" +
				"itemNumber      = " + itemNumber + "\n" +
				"paymentStatus   = " + paymentStatus + "\n" +
				"paymentAmount   = " + paymentAmount + "\n" +
				"paymentCurrency = " + paymentCurrency + "\n" +
				"receiverEmail   = " + receiverEmail + "\n" +
				"payerEmail      = " + payerEmail);
	}
	else if(res.equals("INVALID"))
	{
		// log for investigation
		l.warn(res);
	}
	else
	{
		// error
		l.warn(res);
	}
	l.info("-----------------");
	
	// process the subscription
	
	// send myself a notification email
	
	// send notification email to new user
	PstUserAbstractObject pstuser = (PstUserAbstractObject) PstGuest.getInstance();
	String subj = "[CR-subscription] " + txnId + " (" + payerEmail + ")";
	String msg1 = "PayPal IPN notification - " + res + "<br>";
	msg1 += "<blockquote>";
	msg1 += "<table border='0' cellspacing='2' cellpadding='2'>";
	msg1 += "<tr><td class='plaintext' width='150'><b>txnId</b>:</td><td class='plaintext'>" + txnId + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>payerEmail</b>:</td><td class='plaintext'>" + payerEmail + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>itemName</b>:</td><td class='plaintext'>" + itemName + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>itemNumber</b>:</td><td class='plaintext'>" + itemNumber + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>paymentStatus</b>:</td><td class='plaintext'>" + paymentStatus + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>paymentAmount</b>:</td><td class='plaintext'>" + paymentAmount + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>paymentCurrency</b>:</td><td class='plaintext'>" + paymentCurrency + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>receiverEmail</b>:</td><td class='plaintext'>" + receiverEmail + "</td></tr>";
	msg1 += "</table></blockquote><br><br>";
	Util.sendMailAsyn(pstuser, FROM, FROM, null, null, subj, msg1, MAILFILE);

%>
