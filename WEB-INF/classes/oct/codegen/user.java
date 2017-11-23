
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   user.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of user class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@AGQ040706	Created get full name method
//		@AGQ081706 	Sets given ids and emails into Contact list
//		@AGQ081706	Add remove attribute method with ignore case
//
/////////////////////////////////////////////////////////////////////
//
// user.java : implementation of the user class
//

package oct.codegen;
import java.util.ArrayList;

import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpCommitObjectException;
import oct.pmp.exception.PmpDeleteObjectException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpObjectException;
import oct.pmp.exception.PmpRawGetException;
import oct.pmp.exception.PmpTypeMismatchException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.StringUtil;
import util.Util;
import util.Util2;

/**
*
* <b>General Description:</b>  user extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "user" organization.
*
* The user class provides a facility to modify data of an existing user object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.userManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
* 
* 	@ECC141019	Added Contacts attribute to the user organization to hole the contacts of this user.  Contacts attribute holds the user ids.
* 				separated by semi-colons.  Guests are held as emails in GuestEmails. At this stage we are only handling guests for meeting, not project.
* 
* 				Contacts are sorted by full-name of the corresponding contacts.  Contacts are generated in two ways in CPM at this point, namely from 
* 				project membership and from participating in the same meeting.  When a user join a project, he will be added to the Contacts of all
* 				members by a thread. Likewise, users invited to a meeting will cross connect to all participants.
* 
* 				Both meeting (post_mtg_new.jsp, post_mtg_upd1.jsp) and project (post_updproj.jsp) use UtilThread to handle cross adding of contacts
* 				to the members.
*
*/


public class user extends PstUserAbstractObject

{
	// Public attributes
	public static final String ROLE_GUEST		= "Guest";
	public static final String ROLE_USER		= "User";
	public static final String ROLE_MANAGER		= "Manager";
	public static final String ROLE_DIRECTOR	= "Director";
	public static final String ROLE_PROGMGR		= "Program Manager";
	public static final String ROLE_VENDOR		= "Vendor";
	public static final String ROLE_ADD_PROJ	= "Add Project";
	public static final String ROLE_ACCTMGR		= "Account Manager";		// CR-MultiCorp sales managing accounts
	public static final String ROLE_ADMIN_ASST	= "Admin Assistant";
	public static final String ROLE_ADMIN		= "Site Administrator";
	public static final String [] ROLE_ARRAY	= {ROLE_GUEST, ROLE_USER, ROLE_MANAGER, ROLE_PROGMGR, ROLE_DIRECTOR, ROLE_VENDOR, ROLE_ADD_PROJ, ROLE_ACCTMGR, ROLE_ADMIN_ASST, ROLE_ADMIN};

	public static final int iROLE_USER			= 1;
	public static final int iROLE_MANAGER		= 2;
	public static final int iROLE_DIRECTOR		= 4;
	public static final int iROLE_PROGMGR		= 8;
	public static final int iROLE_VENDOR		= 16;
	public static final int iROLE_GUEST			= 32;
	public static final int iROLE_ADD_PROJ		= 64;
	public static final int iROLE_ACCTMGR		= 128;
	public static final int iROLE_ADMIN_ASST	= 256;
	public static final int iROLE_ADMIN			= 4096;		// site admin
	public static final int [] iROLE_ARRAY	= {iROLE_GUEST, iROLE_USER, iROLE_MANAGER, iROLE_PROGMGR, iROLE_DIRECTOR, iROLE_VENDOR, iROLE_ADD_PROJ, iROLE_ACCTMGR, iROLE_ADMIN_ASST, iROLE_ADMIN};

	public static final String TEAMMEMBERS = "TeamMembers";
	public static final String GUESTEMAILS = "GuestEmails";
	public static final String EMAIL = "Email";
	public static final String SKYPENAME = "SkypeName";
	public static final String FIRSTNAME = "FirstName";
	public static final String LASTNAME = "LastName";

	//	Private attributes
	static Logger l = PrmLog.getLog();

    static userManager manager;
    static townManager tnMgr;
    static userinfoManager uiMgr;
    static projectManager pjMgr;

    static {
		try {
            manager = userManager.getInstance();
			tnMgr = townManager.getInstance();
			uiMgr = userinfoManager.getInstance();
			pjMgr = projectManager.getInstance();
		}
		catch (PmpException e) {}
	}

    /**
     * Constructor for instantiating a new user.
     * @param member An OmsMember representing a user.
     */
    public user(OmsMember member)
    {
        super(member);
    }//End Constructor





    /**
     * Constructor for instantiating a new user.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	user(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a user.  Used by userManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the user.
     */
    user(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
    }//End Constructor

    /**
     * Constructor for creating a user.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the user.
     */
    user(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
    }//End Constructor

    /**
     * Constructor for creating a user using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the user.
     * @param userMemName The member name for the created user.
     */
    user(PstUserAbstractObject userObj, OmsOrganization org, String userMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, userMemName, null);
    }//End Constructor

    /**
     * Constructor for creating a user using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the user.
     * @param companyMemberName The member name for the created user.
     */
    user(OmsSession session, OmsOrganization org, String userMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, userMemName, null);
    }//End Constructor


    /**
     * Currentyly Not Implemented.
     * Determine whether attribute is settable.
     * @param attributeName Name of attribute.
     */
    private boolean isSetAuthorized(String attributeName)
    {
        return true;

    }//End isSetAuthorized

    /**
     * Set attribute value.
     * @param attributeId The attribute id.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(int attributeId, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValue, false);
    }//End setAttribute

    /**
     * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
     * @param attributeId The attribute id.
     * @param attributeValues The array of values to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(int attributeId, Object [] attributeValues)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValues);
    }//End setAttribute

    /**
     * Append attribute value.
     * @param attributeId The attribute id.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void appendAttribute(int attributeId, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValue, true);
    }//End appendAttribute

    /**
     * Append attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void appendAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
		setAttribute(attributeName, attributeValue, true);
	}

    /**
     * Set attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
		setAttribute(attributeName, attributeValue, false);
	}


    /**
     * Set attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @param bAppend True if the attribute value is to append to the current value list
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    protected void setAttribute(String attributeName, Object attributeValue, boolean bAppend)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(isSetAuthorized(attributeName) == false)
        {
            throw new PmpInvalidAttributeException("Not authorized to set.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            if(attributeValue instanceof byte[] || attributeValue==null)
            {
                super.setRawData(attributeName, (byte [])attributeValue);
            }
            else
            {
                throw new PmpTypeMismatchException("Data is not of RAW type.");
            }
        }
        else
        {
            super.setData(attributeName, attributeValue, bAppend);	// support appending data
        }

    }//End setAttribute


    /**
     * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
     * @param attributeName The attribute name.
     * @param attributeValues The array of values to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(String attributeName, Object [] attributeValues)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValues))
        {
            throw new PmpTypeMismatchException("Attribute values has an incorrect type.");
        }
        else if(manager.getAttributeType(attributeName)== RAW)
        {
            //Delete raw data value if null
            if(attributeValues == null)
            {
                super.setRawData(attributeName,null);
            }
            else
            {
                throw new PmpUnsupportedTypeException("Raw data with multiple values is not supported.");
            }
        }

        if(isSetAuthorized(attributeName) == false)
        {
            throw new PmpInvalidAttributeException("Not authorized to set.");
        }

        super.setData(attributeName, attributeValues);

    }//End setAttribute

    /**
     * Remove an attribute value from a multi-value attribute.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to be remove from the list.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void removeAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
        }
        else
        {
            super.removeData(attributeName, attributeValue);
        }

    }//End removeAttribute
// @AGQ081706
    /**
     * Remove an attribute value ignoring case from a multi-value attribute.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to be remove from the list.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void removeAttributeIgnoreCase(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
        }
        else
        {
            super.removeDataIgnoreCase(attributeName, attributeValue);
        }

    }//End removeAttribute

    /**
     * Get the attribute value.
     * @param attributeId The attribute id.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(int attributeId)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        String attributeName = manager.getAttributeName(attributeId);
        return getAttribute(attributeName);
    }//End getAttribute

    /**
     * Get the attribute value.
     * @param attributeName The attribute name.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(String attributeName)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        if(manager.getAttributeType(attributeName) == RAW)
        {
            byte [] rawResult = super.getRawData(attributeName);
            Object [] finalResult = new Object[1];
            finalResult[0] = rawResult;
            return finalResult;
        }

        if(manager.hasMultipleValues(attributeName))
        {
            return super.getMultipleData(attributeName, manager.getAttributeType(attributeName));
        }
        else
        {
            Object [] finalResult = new Object[1];
            finalResult[0] = super.getSingleData(attributeName, manager.getAttributeType(attributeName));
            return finalResult;
        }

    }//End getAttribute

    // public getAllUsers()
    public PstAbstractObject [] getAllUsers()
    	throws ClassCastException, PmpException
    {
		int allEmpIds[] = manager.findId(this, "om_acctname='%'");
		PstAbstractObject [] allMember = manager.get(this, allEmpIds);

		// sort the user list for owner assignment
		Util.sortUserArray(allMember, true);					// sort by fullname
		return allMember;
	}

    // public getTeamMembers()
    public PstAbstractObject [] getTeamMembers(int projId)
    	throws PmpException
    {
		return getTeamMembers((project)projectManager.getInstance().get(this, projId));
	}

    // public getTeamMembers()
    public PstAbstractObject [] getTeamMembers(project pj)
    	throws ClassCastException, PmpException
    {
		Object [] projTeam = pj.getAttribute("TeamMembers");
		PstAbstractObject [] teamMember = manager.get(this, projTeam);

		// sort the employee list for owner assignment
		Util.sortUserArray(teamMember, true);
		return teamMember;
	}

// @AGQ040706
    /**
     * Retrieves the full name of the current user
     * @return 	the full name
     * 			or first name if last name is null
     * 			or null if cannot retrieve name
     */
    public String getFullName() {
    	try {
	    	StringBuffer sb = new StringBuffer(128);
	    	String firstName = getStringAttribute(FIRSTNAME);
	    	sb.append(firstName);
	    	String lastName = (String)getAttribute(LASTNAME)[0];
	    	if (lastName != null
	    			&& lastName.charAt(0)!='?' && lastName.charAt(0)!='.') {	// lastName might just be an "?"
	    		if (!StringUtil.isMultiByte(firstName))
	    			sb.append(' ');		// for Chinese, don't add space
	    		sb.append(lastName);
	    	}
	    	return sb.toString();
    	} catch (PmpException e) {
    		return null;
    	}
    }

    /**
     */
    public static String getFullName(PstUserAbstractObject u, String uIdS)
    {
    	if (Util.isNullOrEmptyString(uIdS)) return null;
		try {
			user uObj = (user)manager.get(u, Integer.parseInt(uIdS));
			return uObj.getFullName();
		} catch (PmpException e) {return null;}
	}

    /**
     */
    public String getShortName()
    {
    	try {
	    	StringBuffer sb = new StringBuffer(128);
	    	sb.append(getAttribute(FIRSTNAME)[0]);
	    	String lastName = (String)getAttribute(LASTNAME)[0];
	    	if (lastName != null && lastName.charAt(0)!='?') {	// lastName might just be an "?"
	    		sb.append(' ');
	    		sb.append(lastName.substring(0,1).toUpperCase() + ".");
	    	}
	    	return sb.toString();
    	} catch (PmpException e) {
    		return null;
    	}
    }


// @AGQ081706
    /**
     * Set the user Ids and email address into my Contact list. Ignores
     * my own id.
     * @param intArr
     * @param emailArr
     * @return
     */
    public boolean setContactList(Integer [] intArr, ArrayList emailArr) {
    	try {
    		// ECC rewrite
    		addContacts(intArr);
    		/*for (int i=0; i<intArr.length; i++) {
    			appendAttribute(TEAMMEMBERS, intArr[i]);
    		}*/
    		
    		// guest
    		int size = emailArr.size();
    		for (int i=0; i<size; i++) {
    			appendAttribute(GUESTEMAILS, emailArr.get(i));
    		}
    		return true;
    	} catch (PmpException e) {
    		return false;
    	}
    }

    /**
    */
    public String getGuestName()
    	throws PmpException
    {
		Integer tInt = (Integer)getAttribute("Towns")[0];
		if (tInt == null) return "";
		int tid = tInt.intValue();
		PstAbstractObject tn = tnMgr.get((PstUserAbstractObject)this, tid);
		String tnName = (String)tn.getAttribute("Name")[0];
		if (tnName == null) tnName = tn.getObjectName();

		String guestName = tnName.replaceAll(" ", "").replaceAll("'", "").replaceAll("/", "");
		return guestName;
	}

    /**
    */
    public boolean isCircleGuest()
    	throws PmpException
    {
		return getObjectName().equalsIgnoreCase(getGuestName());
	}
    
    /**
     */
    public String getUserCompanyID()
    	throws PmpException
    {
    	String cid = getStringAttribute("Company");
    	if (cid == null) cid = getStringAttribute("TownID");
    	return cid;
    }
    
    /**
     */
    public town getUserTown()
		throws PmpException
    {
    	String tidS = getUserCompanyID();
    	if (tidS == null) return null;
    	town tn = (town) tnMgr.get(this, Integer.parseInt(tidS));
    	return tn;
    }

    protected void delete()
        throws PmpDeleteObjectException
    {
    	// delete the userinfo object
    	int myUid = getObjectId();
    	try {
    		userinfo ui = (userinfo)uiMgr.get(this, String.valueOf(myUid));
    		uiMgr.delete(ui);
    	}
    	catch (PmpException e) {l.error("user.delete() failed to delete userinfo for user [" + myUid + "]");}
    	
    	// delete personal project space if any
    	try {
	    	int [] ids = pjMgr.findId(this, "Owner='" + getObjectId() + "' && Option='%" + project.PERSONAL + "%'");
	    	for (int i=0; i<ids.length; i++) {
	    		pjMgr.delete(pjMgr.get(this, ids[i]));
	    		l.info("user.delete() removed personal project [" + ids[i] + "] for user [" + myUid + "]");
	    	}
    	}
    	catch (PmpException e) {l.error("user.delete() failed to delete personal project for user [" + myUid + "]");}
    	
        super.delete();
    }//End delete

    protected void save()
        throws PmpCommitObjectException
    {
        super.save();
    }//End save

    protected boolean refresh()
    {
        return super.refresh();
    }//End refresh



    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // CONTACTS
    //
    
	/**
	 * return the contacts of this user in an int array.  Note that the return user ids are already sorted by the corresponding
	 * contact's full name.
	 * @return
	 * @throws PmpException
	 */
	public int[] getContacts() 
		throws PmpException
	{
		// get the Contacts attribute from the user and return it as an int[].  Note that Content contains the contacts in sorted order by name.
		// Content stores the uids: 12345;22233;10101; ...
		return Util2.toIntArray(getAttribute("TeamMembers"));
		
		/*String contactS = getRawAttributeAsString("Contacts");
		if (StringUtil.isNullOrEmptyString(contactS)) return new int[0];
		
		String [] contactArr = contactS.split(";");
		return Util2.toIntArray(contactArr);*/
	}
	
	public void addContacts(String idS)
		throws PmpException
	{
		if (StringUtil.isNullOrEmptyString(idS)) return;
		appendAttribute("TeamMembers", Integer.parseInt(idS));
		/*String [] sArr = new String[1];
		sArr[0] = idS;
		return addContacts(sArr[0]);*/
	}
	
	/**
	 * merge the new id arrays to this user's contact list.
	 * @param idArr		array of user ids (Integer or String) to be added as contacts.
	 * @throws PmpException
	 */
	public void addContacts(Object [] idArr)
		throws PmpException
	{
		int [] intArr = Util2.toIntArray(idArr);
		appendAttribute("TeamMembers", intArr);
		return;
		
		/*
		// the idArr may be Integer array (called by project) or String array (called by meeting)
		if (idArr==null || idArr.length<=0) return;
		int [] ids = Util2.toIntArray(idArr);
		
		int [] contacts = getContacts();
		int oldNum = contacts.length;
		contacts = Util2.mergeIntArray(contacts, ids);		// will eliminate duplicate

		/////////////
		// sort
		//PstAbstractObject [] uObjArr = manager.get(this, contacts);	// not good: i don't want to abort because of one user is bad
		PstAbstractObject [] uObjArr = new PstAbstractObject [contacts.length];
		for (int i=0; i<contacts.length; i++) {
			if (contacts[i] <= 0) {
				uObjArr[i] = null;
			}
			else {
				try {uObjArr[i] = manager.get(this, contacts[i]);}
				catch (PmpException e) {
					l.warn("addContacts() found bad uid [" + contacts[i] + "] - skip.");
					uObjArr[i] = null;
				}
			}
		}
		Util.sortUserArray(uObjArr, true);					// sort by fullname
		
		// extract the uid's back as int[]
		contacts = new int[uObjArr.length];
		for (int i=0; i<uObjArr.length; i++) {
			if (uObjArr[i] == null) {
				contacts[i]	 = -9999;
			}
			else {
				contacts[i] = uObjArr[i].getObjectId();
			}
		}
		// done sort
		///////////////
		
		
		// store into raw attribute
		int myUid = getObjectId();
		String s = "";
		int newNum = 0;
		for (int id : contacts) {
			if (id <= 0) continue;							// invalid user
			if (id == myUid) continue;						// skip myself
			if (s.length() > 0) s += ";";
			s += String.valueOf(id);
			newNum++;
		}
		
		setAttribute("Contacts", s.getBytes());
		save();
		
		return (newNum-oldNum);								// number of newly added contacts
		*/
	}
	
	/**
	 * print to System.out a list of this user's contact's full-name
	 * @throws PmpException
	 */
	public void printContacts()
		throws PmpException
	{
		int [] contacts = getContacts();
		user u;
		
		System.out.println("-- contacts for [" + this.getObjectId() + "]");
		for (int id : contacts) {
			try {u = (user) manager.get(this, id);}
			catch (PmpException e) {continue;}
			System.out.println("  " + u.getFullName());
		}
		System.out.println("\n");
	}

}//End class user
