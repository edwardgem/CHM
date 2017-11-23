//
//  Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   RoboMail.java
//  Author:	ECC
//  Date:   11/14/08
//  Description:
//			Receive POP3 email for background thread of PRM to handle requests.
//			Modified from Tim Archer
//  Modification:
//
//
/////////////////////////////////////////////////////////////////////
//
// RoboMail.java : implementation of the RoboMail class for PRM
//
package util;

import java.util.Properties;

import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Store;

import org.apache.log4j.Logger;

/**
 * Utility class used for logging into a RoboMail (CR) server account
 * and processing messages in it. You can retrieve the unread message count,
 * message details, delete the messages, etc.
 *
 * @author  Tim Archer 09/30/2003
 * @version $Revision: 1.1 $
 */
public class RoboMail {
    public static Logger l = PrmLog.getLog();

    /**The URL of the RoboMail server to connect to. This is set in the constructor
     * to the value: "RoboMail://"+username+":"+password+"@"+hostname; */
    protected String url = "";
    /**The hostname of the RoboMail server to connect to. */
    protected String hostname = "";
    /**The username to connect to the RoboMail server with. */
    protected String username = "";
    /**The password to connect to the RoboMail server with. */
    protected String password = "";

    /** The message store. */
    protected Store store = null;
    /** The Folder representing the users inbox. */
    protected Folder inboxFolder = null;

    /**
     * Constructor.
     *
     * @param p_hostname the hostname of the RoboMail server to connect to
     * @param p_username the username to login to the RoboMail account as
     * @param p_password the password to use when logging into the RoboMail account
     * @throws Exception If an error occurs.
     *
     */
    public RoboMail (String p_hostname, String p_username, String p_password) throws Exception {
        hostname = p_hostname;
        username = p_username;
        password = p_password;
        // url is formatted as
        url = "pop3://"+username+":"+password+"@"+hostname;
    }

    /**
     * Connect to the RoboMail server.
     *
     * @throws Exception If an error occurs.
     */
    public void connect () throws Exception {
        boolean debug = false;

        // Get a Properties object
        Properties props = System.getProperties();

        // Get a Session object
        Session session = Session.getInstance(props);	//Session.getDefaultInstance(props, null);
        session.setDebug(debug);

        // Get a Store object
        try {
        	// Smartermail service required this way of connect, doesn't access the url format
            Store store = session.getStore("pop3");
            store.connect(hostname, username, password);

			inboxFolder = store.getFolder("INBOX");
			inboxFolder.open(Folder.READ_WRITE);		//Folder.READ_ONLY

//            URLName urln = new URLName(url);
//            store = session.getStore(urln);
//            store.connect();
        } catch (MessagingException e) {
            throw new Exception ("Unable to connect to RoboMail server. "+e.toString()
            		+ "\n   url=" + url);
        }
        //l.info("RoboMail - Successfully open " + username + " INBOX for read");

/*        try {
            // Open the Folder

            inboxFolder = store.getFolder("INBOX");
            inboxFolder.open(Folder.READ_ONLY);		//Folder.READ_WRITE
            
        } catch (Exception e) {
        	e.printStackTrace();
            throw new Exception ("Unable to open folder. "+e.toString());
        }
*/        
        
    }	// END: connect()

    /**
     * Disconnect from the RoboMail server.
     *
     * @throws Exception If an error occurs.
     */
    public void disconnect () throws Exception {
        try {
            inboxFolder.close(true);
        } catch (Exception e) {
            throw new Exception ("Unable to close the RoboMail Folder. "+e.toString());
        }

        try {
        	if (store != null) {
            	store.close();
        	}
        } catch (Exception e) {
            throw new Exception ("Unable to disconnect from RoboMail server. "+e.toString());
        }
    }

    /**
     * Returns the number of messages in the users inbox.
     * @return int The number of messages in the users inbox.
     * @throws Exception If an error occurs.
     *
     */
    public int getMessageCount() throws Exception {
        return inboxFolder.getMessageCount();
    }

    /**
     * Returns the number of unread messages in the users folder.
     * @return int The number of unread messages in the users folder.
     * @throws Exception If an error occurs.
     *
     */
    public int getUnreadMessageCount() throws Exception {
        return inboxFolder.getUnreadMessageCount();
    }

    /**
     * Returns the number of new messages in the users folder.
     * @return int The number of new messages in the users folder.
     * @throws Exception If an error occurs.
     *
     */
    public int getNewMessageCount() throws Exception {
        return inboxFolder.getNewMessageCount();
    }


    /**
     * Get the Message object corresponding to the given message number.
     * @param msgnum The index/message number of the message to get.
     * @return Message The message at the specified index.
     * @throws Exception If an error occurs.
     *
     */
    public Message getMessage(int msgnum) throws Exception{
        return inboxFolder.getMessage(msgnum);
    }

    /**
     * Get all Message objects from this Folder.
     * @return Message[] The array of messages.
     * @throws Exception If an error occurs.
     *
     */
    public Message[] getMessages() throws Exception{
        return inboxFolder.getMessages();
    }

    /**
     * Get the Message objects for message numbers specified in the array.
     * @param msgnums An integer array containing the index/message
     * number of the messages to get.
     * @return Message[] The array of messages.
     * @throws Exception If an error occurs.
     *
     */
    public Message[] getMessages(int[] msgnums) throws Exception {
        return inboxFolder.getMessages(msgnums);
    }

    /**
     * Get the Message objects for message numbers ranging from start through
     * end, both start and end index inclusive.
     * @param start The index/message number to start getting messages at.
     * @param end The index/message number to stop getting messages at.
     * @return Message[] The array of messages.
     * @throws Exception If an error occurs.
     *
     */
    public Message[] getMessages(int start, int end) throws Exception{
        return inboxFolder.getMessages(start, end);
    }

}
