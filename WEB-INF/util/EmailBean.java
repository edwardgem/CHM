package util;

import java.util.ArrayList;

public class EmailBean {
	private ArrayList 	foundEmail;	// Emails in database
	private ArrayList 	newEmail;	// Emails not in database
	private String		myEmail; 	// Set when found
	
	public EmailBean() {
		foundEmail 	= new ArrayList();
		newEmail	= new ArrayList();
		myEmail		= null;
	}
	
	public void addFoundEmail(String email) {
		foundEmail.add(email);
	}

	public void setMyEmail(String email) {
		myEmail = email;
	}

	public void addNewEmail(String email) {
		newEmail.add(email);
	}

	public Object [] getFoundEmail() {
		return foundEmail.toArray();
	}

	public String getMyEmail() {
		return myEmail;
	}

	public Object [] getNewEmail() {
		return newEmail.toArray();
	}
	
	
}
