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
//  File:   userManager.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//    This is a class that represent the container of user classes.
//
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@AGQ081706A	Removes userId from Contact list when users are deleted
//		@AGQ081706	Convert Guest emails to User Ids    
//
/////////////////////////////////////////////////////////////////////
//
// userManager.java : For user object container manipulation
//

package oct.codegen;
import java.util.ArrayList;
import java.util.Date;

import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.omm.common.OmsException;
import oct.omm.common.OmsObList;
import oct.omm.common.OmsObject;
import oct.pmp.exception.PmpAddAttributeException;
import oct.pmp.exception.PmpAttributeNotFoundException;
import oct.pmp.exception.PmpCommitObjectException;
import oct.pmp.exception.PmpDeleteObjectException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpIllegalTypeException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpObjectNotFoundException;
import oct.pst.PstAbstractObject;
import oct.pst.PstSystem;
import oct.pst.PstUserAbstractObject;
import util.EmailBean;
import util.PrmEvent;
import util.Util;

 /**
  *
  * <b>General Description:</b>  userManager extends PstManager.  This class
  * manages all user objects such as creating, retrieving, saving, and
  * deleting user objects.
  *
  * userManager can only instantiated through the getInstance() method.
  *
  *
  * <b>Class Dependencies:</b>
  *   oct.codegen.user
  *   oct.pst.PstUserAbstractObject
  *   oct.pst.PstUserManager
  *   oct.pst.PstAbstractObject
  *   oct.pst.PstManager
  *
  *
  * <b>Miscellaneous:</b> None.
  *
  */


public class userManager extends oct.pst.PstUserManager

{
    public static final String NAME = "user";     // The orgname of Object user
    public static final String CLASSNAME = "oct.codegen.user";     // The className of Object user
    private static final boolean isMultiCorp = (Util.getPropKey("pst", "MULTICORPORATE").equalsIgnoreCase("true"));

    private static userManager manager = null;


    /**
     * Construct an empty user object
     * @param userObj A PstUserAbstractObject.
     */
    private userManager(PstUserAbstractObject userObj)
        throws PmpManagerCreationException
    {
        super(userObj, NAME, CLASSNAME);
    }

    /**
     * Instantiates a userManager object.
     * @return A userManager.
     */
    public static userManager getInstance()
        throws PmpManagerCreationException, PmpInternalException
    {
        if(manager == null)
        {
            manager = new userManager(PstSystem.getInstance());
        }
        return manager;
    }//End getInstance


    /**
     * Create a new user object.
     * @param userObj The PstUserAbstractObject who is requesting to create a user.
     * @param type The type of user to create.<br>
     * @param userName The name of the user.
     *
     * @exception PmpObjectCreationException There was an error creating the user.
     * @exception PmpIllegalTypeException The specified compnaytype is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a user object.
     */
    public PstAbstractObject create(PstUserAbstractObject userObj, String userName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        return create(userObj.getSession(), userName);
    }//End create

    /**
     * Create a new user object.
     * @param session An OmsSession.
     * @param type The type of user to create.<br>
     * @param userName The name of the user.
     * @exception PmpObjectCreationException There was an error creating the user.
     * @exception PmpIllegalTypeException The specified user type is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a user object.
     */
    PstAbstractObject create(OmsSession session, String userName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        user user = null;
        if(userName == null || userName.length() == 0)
        {
            throw new PmpObjectCreationException("The user name cannot be empty.");
        }

        try
        {

            user = new user(session,m_organization, userName);
            return user;
        }
        catch(PmpException pe)
        {
            if(user != null)
            {
                try
                {
                    delete(user);
                }
                catch(Exception e1)
                {
                }
            }
            throw new PmpObjectCreationException("Error creating user object:" + pe.toString());
        }
    }//End create


    /**
     * create creates a new user of the specified type
     * @param userObj - the user asking to create a user
     * @param type - the type of user to create (i.e. SELLER, BUYER_ADMIN, etc.)  see public static constants
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject userObj, String memberName, String password)
    	throws PmpObjectCreationException, PmpInternalException
    {
		user newUser = null;
		try
		{
			newUser = new user(userObj, m_organization, memberName, password);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException(e.toString());	//"Cannot create new user");
		}

		return newUser;
    }


    /**
     * create creates a new user and the associated userinfo
     * @param userObj - the user asking to create a user
     * @param type - the type of user to create (i.e. SELLER, BUYER_ADMIN, etc.)  see public static constants
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user/userinfo in the databse
     * @exception PmpInternalException - could not create the user/userinfo
     */
    public PstAbstractObject createFull(PstUserAbstractObject userObj, String memberName, String password)
    	throws PmpObjectCreationException, PmpInternalException
    {
    	user newUser = (user)create(userObj, memberName, password);
    	
    	// now create new userInfo object
		try
		{
			// create userinfo
			userinfoManager uiMgr = userinfoManager.getInstance();
			userinfo ui = (userinfo)uiMgr.create(newUser, String.valueOf(newUser.getObjectId()));
			ui.setAttribute("Preference", "BlogCheck:Mon");
			uiMgr.commit(ui);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException(e.toString());
		}

		return newUser;
    }


    /**
     * create creates a new object with generated member name
     * @param userObj - the user asking to create a user
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject userObj)
    	throws PmpObjectCreationException, PmpInternalException
    {
		user newUser = null;
		try
		{
			newUser = new user(userObj, m_organization);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new user");
		}

		return newUser;
    }




    /**
     *
     * Obtain a user object from database.
     * @param userObj  PstUserAbstractObject requesting a user object.
     * @param objectId Object id of the user object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a user object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectId);
    }//End get

    /**
     *
     * Obtain a user object from database.
     * @param session  An OmsSession.
     * @param objectId Object id of the user object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a user object.
     */
    PstAbstractObject get(OmsSession session, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session,objectId);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in user organization.");
            }

            //Return a user object
            return new user(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain a user object from the database.
     * @param userObj  A PstUserAbstractObject.
     * @param objectName Object name of the user object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a user object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(),objectName);
    }//End get

    /**
     *
     * Obtain a user object from the database.
     * @param session  An OmsSession.
     * @param objectName Object name of the user object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a user object.
     */
    PstAbstractObject get(OmsSession session, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session, super.m_organization, objectName);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in user organization.");
            }
            //Return a user object
            return new user(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of user objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the user objects.
     * @param objectIds Object ids of all user objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a user object.
     *   <b>NOTE:</b>  The arrays of user will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectIds);
    }//End get

    /**
     *
     * Obtain an array of user objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the user objects.
     * @param objectIds Object ids in an Integer array of all user objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a user object.
     *   <b>NOTE:</b>  The arrays of user will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, Object [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		int count = objectIds.length;
		int [] ia = new int [count];
		for (int i=0; i<count; i++)
			ia[i] = ((Integer)objectIds[i]).intValue();
        return get(userObj.getSession(), ia);
    }//End get

    /**
     *
     * Obtain a Company object based on a set of user ids.
     * Obtain an array of user objects based on a set of specified object ids.
     * @param session  PstUserAbstractObject requesting the user objects.
     * @param objectIds Object ids of all user objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a user object.
     *   <b>NOTE:</b>  The arrays of user will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            int count = objectIds.length;
            if(count <1)
            {
                    return new user[0];
            }

            OmsOrganization org = super.m_organization.copyOrg(session);

            //Set up a list of OmsObject to pass to getMultiMembers
            OmsObList idList = new OmsObList(OmsObject.OMS_OBJECT_LST);
            for(int i=0; i<count; i++)
            {
                OmsObject obj = new OmsObject();  //Note: obj does not contain memname
                obj.setId(objectIds[i]);
                idList.add(obj);
            }

            OmsObList memList = org.getMultiMembers(idList);  //Get the multiple members
            int newCount = memList.size();

            user [] result = new user[newCount];

            for(int i=0; i<newCount; i++)
            {
                OmsMember member = (OmsMember) memList.get(i);
                //Return a user object
                result[i] = new user(member);

            }

            return result;
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of user objects based on a set of specified user member names.
     * @param userObj  PstUserAbstractObject requesting the user objects.
     * @param objectNames Object names of all user objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a user object.
     *   <b>NOTE:</b>  The arrays of user will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectNames);
    }//End get

    /**
     *
     * Obtain an array of user objects based on a set of specified user member names.
     * @param session  PstUserAbstractObject requesting the user objects.
     * @param objectNames Object names of all user objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a user object.
     *   <b>NOTE:</b>  The arrays of user will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        int count = objectNames.length;
        if(count <1)
        {
                    return new user[0];
        }

        ArrayList result = new ArrayList();

        for(int i=0; i<count; i++)
        {
            try
            {
                result.add(get(session,objectNames[i]));
            }
            catch (PmpException pe)
            {
                continue;  //Skip bad objectNames
            }
        }
        int newCount = result.size();

        user [] newResult = new user[newCount];
        for(int i=0; i<newCount; i++)
        {
            newResult[i] = (user) result.get(i);
        }

        return newResult;

    }//End get

    /**
     *
     * Delete the member from the database.
     * @param dataObject The user object to delete permanently.
     * @exception PmpDeleteObjectException Could not delete the specified object.
     */
    public void delete(PstAbstractObject dataObject)
        throws PmpDeleteObjectException
    {
    	// @AGQ081706A
    	removeUserIds((user) dataObject);
        ((user)dataObject).delete();

    }//End delete

    /**
     *
     * Save the member to the database.
     * @param dataObject The user object to save.
     * @exception PmpCommitObjectException Could not save the specified object.
     */
    public void commit(PstAbstractObject dataObject)
        throws PmpCommitObjectException
    {
        ((user)dataObject).save();

    }//End commit

    /**
     *
     * Refresh the member. Currently, not implemented.
     * @param dataObject The user object to refresh.
     */
    public void refresh(PstAbstractObject dataObject)
    {
        ((user)dataObject).refresh();

    }//End refresh



    /**
     * Obtain a List of user objects that belongs to the user.
     *
     * @param userObj - PstUserAbstractObject requesting the user objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of user objects that is own by this user.
     *
     */
    public PstAbstractObject [] getAlluser(PstUserAbstractObject userObj)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		String expr = "(om_acctname='%')";

		int id[] = this.findId(userObj.getSession(), expr);

		if (id == null)
			return null;

		PstAbstractObject objArray[] = this.get(userObj, id);

        return objArray;
    }

// @AGQ081706    
    /**
     * Searches all the users and meeting objects for the given user's email
     * address. Removes the email from GuestEmails attribute and adds it to
     * TeamMembers for users and Attendee for meetings.
     * @param userObj 	The newly registered user
     * @return	The numbers of converted objects 
     */
    public int convertGuestEmailsToUser(PstUserAbstractObject userObj) {
    	int counter = 0;
    	try {
    		String email = (String) userObj.getAttribute(user.EMAIL)[0];    		
    		String exp = user.GUESTEMAILS+"='"+email+"'";
    		int [] intArr = findId(userObj, exp);
    		PstAbstractObject [] pstObjArr = get(userObj, intArr);
    		user u;
    		Integer uId = Integer.valueOf(userObj.getObjectId());
    		// Removes email from guestemails and adds uid to teammemeber
    		for (int i=0; i<pstObjArr.length; i++) {
    			u = (user) pstObjArr[i];
    			u.removeAttributeIgnoreCase(user.GUESTEMAILS, email);
    			u.appendAttribute(user.TEAMMEMBERS, uId);
    			commit(u);
    			
    			// event: userObj (guest) has become my friend
    			PrmEvent.createTriggerEventDirect(userObj, PrmEvent.EVT_FRN_ACCEPT, u.getObjectId());
    			
    			counter++;
    			
       			// I have become userObj's friend   			
    			userObj.appendAttribute(user.TEAMMEMBERS, Integer.valueOf(u.getObjectId()));
    		}	
    		commit(userObj);
    		
    		meetingManager mMgr = meetingManager.getInstance();
    		intArr = mMgr.findId(userObj, exp);
    		pstObjArr = mMgr.get(userObj, intArr);
    		meeting m;
    		// Removes email from guestemails and adds uid to attendee as optional
    		for (int i=0; i<pstObjArr.length; i++) {
    			m = (meeting) pstObjArr[i];
    			m.removeAttributeIgnoreCase(meeting.GUESTEMAILS, email);
    			m.appendAttribute(meeting.ATTENDEE, uId+meeting.DELIMITER+meeting.ATT_OPTIONAL);
    			mMgr.commit(m);
    			counter++;
    		}
    	} catch (PmpException e) {
    		e.printStackTrace();
    	}
    	return counter;
    }
    
    public EmailBean convertEmailToUserAdd(PstUserAbstractObject userObj, String [] emailArr) {
    	EmailBean emailBean = new EmailBean();
    	int uIdi = userObj.getObjectId();
		Integer uId = Integer.valueOf(uIdi);
		
    	for (int i=0; i<emailArr.length; i++) {
    		try {
	    		String curEmail = emailArr[i];
	    		String exp = user.EMAIL+"='"+curEmail+"'";
	    		int [] intArr = findId(userObj, exp);
	    		// Found
	    		if (intArr.length > 0) {
		    		PstAbstractObject [] pstObjArr = get(userObj, intArr);
		    		user u;
		    		int curUidi;
		    		// This algorithm assumes only one distinct email per user
		    		for (int j=0; j<pstObjArr.length; j++) {
		    			u = (user) pstObjArr[j];
		    			curUidi = u.getObjectId();
		    			if (curUidi == uIdi) { // Found my own email
		    				emailBean.setMyEmail(curEmail);
		    			}
		    			else {
		    				// Add user to both account
			    			u.appendAttribute(user.TEAMMEMBERS, uId);
			    			commit(u);
			    			userObj.appendAttribute(user.TEAMMEMBERS, Integer.valueOf(curUidi));
			    			commit(userObj);
			    			emailBean.addFoundEmail(curEmail);
		    			}
		    		}
	    		}
	    		// Not Found
	    		else {
	    			emailBean.addNewEmail(curEmail);
	    		}
	    	} catch (PmpException e) {
	    		e.printStackTrace();
	    	}
    	}
    	return emailBean;
    }
    
// @AGQ081706A
    /**
     * Removes all the user ids from the Contact list for users.
     * Does not remove from meetings because it should keep a 
     * record.
     * @param userObj
     * @return
     */
    public int removeUserIds(PstUserAbstractObject userObj) {
    	int counter = 0;
    	try {
    		Integer uId = Integer.valueOf(userObj.getObjectId());
    		String exp = user.TEAMMEMBERS+"="+uId;
    		int [] intArr = findId(userObj, exp);
    		PstAbstractObject [] pstObjArr = get(userObj, intArr);
    		user u;
    		
    		// Removes TeamMember id from user object
    		for (int i=0; i<pstObjArr.length; i++) {
    			u = (user) pstObjArr[i];
    			u.removeAttribute(user.TEAMMEMBERS, uId);
    			commit(u);
    			counter++;
    		}
    	} catch (PmpException e) {
    		e.printStackTrace();
    	}
    	return counter;
    }

    /**
     * Add a dynamic attribute to the purchase order object definition
     * @param <b> userObj </b> user object
     * @param <b> attObject </b> object contains information of the attribute to be added
     * @return a list of PstAttributeObject objects
     * @exception PmpAddAttributeException could not add attribute.
     * @exception PmpInternalException internal errors
     */
    public void addAttribute(PstUserAbstractObject userObj, String attributeName, boolean required)
        throws PmpInternalException
    {
        super.addAttribute(userObj, attributeName, required);
    }

    /**
     * Remove an attribute
     * @param <b> userObj </b> user object
     * @param <b> attname </b> name of the attribute to be deleted
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.
     */
    public void removeAttribute(PstUserAbstractObject userObj, String attName)
    	throws PmpInternalException, PmpAttributeNotFoundException, PmpInvalidAttributeException
    {
        super.removeAttribute(userObj,attName);
    }

    /**
     * Return a PstAttributeObject that contains information of the given attribute name,
     * including system and dynmaic attribute.
     * @param <b> userObj </b> user object
     * @param <b> attName </b> name of the attribure to be returned
     * @return a PstAttributeObject object
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.

    public PstAttributeObject getAttribute(PstUserAbstractObject userObj, String attName)
        throws PmpAttributeNotFoundException, PmpInternalException
    {
        PstAttributeObject attribData = super.getAttribute(userObj,attName);
        if(attribData == null)
        {
            throw new PmpAttributeNotFoundException("Attribute does not exist.");
        }
        else
        {
            return attribData;
        }

    }//End getAttribute
*/

    /**
     * Determine whether an attribute name is valid.
     * @param attributeName The name of the attribute.
     * @return A boolean indicating whether the attribute name is valid.
     */
    public boolean isAttributeValid(String attributeName)
    {
        return super.isAttributeValid(attributeName);
    }


    /**
     * Determine whether an attribute is valid and whether the
     * value for the attribute is of the correct type.
     * A valid attribute with a null value will return true.
     * @param attributeName The name of the attribute.
     * @param val The value of the attribute to verify. This can be an array of Object values,
     * but not an array of primitive values.  It will always fail with an array of primitive values.
     * @exception PmpInternalException An internal error occurred.
     * @exception PmpInvalidAttributeException An attribute name is invalid.
     * @return Return whether the attribute value is valid based on whether
     * there is such an attribute and whether the type matched.
     */
    public boolean isValueValid(String attributeName, Object val)
        throws PmpInternalException, PmpInvalidAttributeException
    {
        return super.isValueValid(attributeName,val);
    }// End isValueValid


    /**
     * Determine whether an attribute id is valid.
     * @param attributeId The id of the attribute.
     * @return A boolean indicating whether the attribute id is valid.
     */
    public boolean isAttributeValid(int attributeId)
    {
        return super.isAttributeValid(attributeId);
    }

    /**
     * Determine if the attribute is required.
     * @param obj A PstAbstractObject to verfiy an attribute against.
     * @attributeId The id of the attribute.
     * @return A boolean indicating whether the attribute is required for this PstAbstractObject.
     */
    public boolean isAttributeRequired(PstAbstractObject obj, int attributeId)
        throws PmpInvalidAttributeException, PmpException
    {
        return super.isAttributeRequired(obj, attributeId);

    }//End isAttributeRequired

    /**
     * Determine if the attribute is required.
     * @param obj A PstAbstractObject to verfiy an attribute against.
     * @attributeName The name of the attribute.
     * @return A boolean indicating whether the attribute is required for this PstAbstractObject.
     */
    public boolean isAttributeRequired(PstAbstractObject obj, String attributeName)
        throws PmpInvalidAttributeException, PmpException
    {
        return super.isAttributeRequired(obj,attributeName);
    }

    /**
     * Determine the if the attribute has multiple values.
     * @param attributeId The id of the attribute.
     * @return A boolean indicating whether the attribute can hold multiple values.
     */
    public boolean hasMultipleValues(int attributeId)
        throws PmpInvalidAttributeException
    {
        return super.hasMultipleValues(attributeId);
    }

    /**
     * Determine the if the attribute has multiple values.
     * @param attributeName The name of the attribute.
     * @return A boolean indicating whether the attribute can hold multiple values.
     */
    public boolean hasMultipleValues(String attributeName)
        throws PmpInvalidAttributeException
    {
        return super.hasMultipleValues(attributeName);
    }

    /**
     * Determine the attribute type from a given attribute id.
     * @param attributeId The id of the attribute.
     * @return The value type for the attribute. Possible values are: PstAbstractObject.STRING, PmpAbstractObject.INT, PmpAbstractObject.FLOAT, PmpAbstractObject.DATE, and PstAbstractObject.RAW.
     */
    public int getAttributeType(int attributeId)
        throws PmpInvalidAttributeException, PmpInternalException
    {
        return super.getAttributeType(attributeId);
    }

    /**
     * Determine the attribute type from a given attribute name.
     * @param attributeName The name of the attribute.
     * @return The value type for the attribute. Possible values are: PstAbstractObject.STRING, PmpAbstractObject.INT, PmpAbstractObject.FLOAT, PmpAbstractObject.DATE, and PstAbstractObject.RAW.
     */
    public int getAttributeType(String attributeName)
        throws PmpInvalidAttributeException, PmpInternalException
    {
        return super.getAttributeType(attributeName);
    }

    /**
     * Retrieve the attribute's name given the attribute id.
     * @param attributeId The id of the attribute.
     * @exception PmpInvalidAttributeException The specified attribute id does not exist.
     * @return The String name of the attribute.
     */
    public String getAttributeName(int attributeId)
        throws PmpInvalidAttributeException
    {
        return super.getAttributeName(attributeId);
    }

    /**
     * Retrieve the attribute's id given the attribute name.
     * @param attributeName The name of the attribute.
     * @exception PmpInvalidAttributeException The specified attribute name does not exist.
     * @return The id of the attribute.
     */
    public int getAttributeId(String attributeName)
        throws PmpInvalidAttributeException
    {
        return super.getAttributeId(attributeName);
    }

    /**
     * Obtain all attribute names of this organization.
     * @return An array of all the attribute names for the manager.
     */
    public String [] getAllAttributeNames()
    {
        return super.getAllAttributeNames();
    }

    /**
     * Obtain all attribute ids of this organization.
     * @return An array of all the attribute ids for the manager.
     */
    public int [] getAllAttributeIds()
    {
        return super.getAllAttributeIds();
    }
    
    public PstAbstractObject createUser(PstUserAbstractObject userObj, String memberName, String password)
		throws PmpException
    {
    	return createUser (userObj, memberName, password, false);
    }
    
    public PstAbstractObject createUser(PstUserAbstractObject userObj, String memberName, String password, boolean bFull)
		throws PmpException
    {
    	PstAbstractObject newUser = create(userObj, memberName, password);
    	
    	// create the userinfo object
    	userinfoManager uiMgr = userinfoManager.getInstance();
    	PstAbstractObject ui = uiMgr.create(userObj, String.valueOf(newUser.getObjectId()));
    	
    	// for full create, set up parameters as what CR expects
    	if (bFull)
    	{
			String fName;
    		int idx = memberName.indexOf('@');
    		if (idx != -1)
    			fName = memberName.substring(0, idx);
    		else
    			fName = memberName;
			newUser.appendAttribute(user.TEAMMEMBERS, Integer.valueOf(newUser.getObjectId())); // Append myself to my Contact List
			newUser.setAttribute("FirstName", fName);
			newUser.setAttribute("Email", memberName);
			newUser.setAttribute("Role", user.ROLE_USER);
			newUser.setAttribute("HireDate", new Date());		// ECC: use HireDate as CreatedDate
			newUser.setAttribute("SpaceTotal", new Integer(userinfo.DEFAULT_CR_SPACE));
			newUser.setAttribute("SpaceUsed", new Integer(0));
			if (!isMultiCorp)
			{
				String comName = Util.getPropKey("pst", "COMPANY_NAME");
				int comId = townManager.getInstance().get(userObj, comName).getObjectId();
				newUser.setAttribute("Company", String.valueOf(comId));
				newUser.setAttribute("Towns", new Integer(comId));
			}
			manager.commit(newUser);

			ui.setAttribute("Preference", "BlogCheck:Mon");
    		uiMgr.commit(ui);
    	}
    	return newUser;
    }


}//End class userManager
