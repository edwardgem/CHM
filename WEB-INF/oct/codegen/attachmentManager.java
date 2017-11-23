//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   attachmentManager.java
//  Author: FastPath CodeGen Engine
//  Date:   06-09-06
//  Description:
//    This is a class that represent the container of attachment classes.
//
//  Modification:
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//
/////////////////////////////////////////////////////////////////////
//
// attachmentManager.java : For attachment object container manipulation
//

package oct.codegen;
import java.util.ArrayList;
import java.util.Date;

import mod.se.IndexScheduler;
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

import org.apache.log4j.Logger;

import util.PrmLog;
import util.Util;
import util.Util2;

 /**
  *
  * <b>General Description:</b>  attachmentManager extends PstManager.  This class
  * manages all attachment objects such as creating, retrieving, saving, and
  * deleting attachment objects.
  *
  * attachmentManager can only instantiated through the getInstance() method.
  *
  *
  * <b>Class Dependencies:</b>
  *   oct.codegen.attachment
  *   oct.pst.PstUserAbstractObject
  *   oct.pst.PstUserManager
  *   oct.pst.PstAbstractObject
  *   oct.pst.PstManager
  *
  *
  * <b>Miscellaneous:</b> None.
  *
  */


public class attachmentManager extends oct.pst.PstManager

{
    public static final String NAME = "attachment";     // The orgname of Object attachment
    public static final String CLASSNAME = "oct.codegen.attachment";     // The className of Object attachment
    public static final int MAX_VIEWBY = 20;

    private static attachmentManager manager = null;
	private static int DEF_SEC_LEVEL = -1;
    static Logger l = PrmLog.getLog();


    /**
     * Construct an empty attachment object
     * @param userObj A PstUserAbstractObject.
     */
    private attachmentManager(PstUserAbstractObject userObj)
        throws PmpManagerCreationException
    {
        super(userObj, NAME, CLASSNAME);
    }

    /**
     * Instantiates a attachmentManager object.
     * @return A attachmentManager.
     */
    public static attachmentManager getInstance()
        throws PmpManagerCreationException, PmpInternalException
    {
        if(manager == null)
        {
            manager = new attachmentManager(PstSystem.getInstance());
        }
        return manager;
    }//End getInstance


    /**
     * Create a new attachment object.
     * @param userObj The PstUserAbstractObject who is requesting to create a attachment.
     * @param type The type of attachment to create.<br>
     * @param attachmentName The name of the attachment.
     *
     * @exception PmpObjectCreationException There was an error creating the attachment.
     * @exception PmpIllegalTypeException The specified compnaytype is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a attachment object.
     */
    public PstAbstractObject create(PstUserAbstractObject userObj, String attachmentName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        return create(userObj.getSession(), attachmentName);
    }//End create

    /**
     * Create a new attachment object.
     * @param session An OmsSession.
     * @param type The type of attachment to create.<br>
     * @param attachmentName The name of the attachment.
     * @exception PmpObjectCreationException There was an error creating the attachment.
     * @exception PmpIllegalTypeException The specified attachment type is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a attachment object.
     */
    PstAbstractObject create(OmsSession session, String attachmentName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        attachment attachment = null;
        if(attachmentName == null || attachmentName.length() == 0)
        {
            throw new PmpObjectCreationException("The attachment name cannot be empty.");
        }

        try
        {

            attachment = new attachment(session,m_organization, attachmentName);
            return attachment;
        }
        catch(PmpException pe)
        {
            if(attachment != null)
            {
                try
                {
                    delete(attachment);
                }
                catch(Exception e1)
                {
                }
            }
            throw new PmpObjectCreationException("Error creating attachment object:" + pe.toString());
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
		attachment newUser = null;
		try
		{
			newUser = new attachment(userObj, m_organization, memberName, password);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new attachment");
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
		attachment newUser = null;
		try
		{
			newUser = new attachment(userObj, m_organization);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new attachment");
		}

		return newUser;
    }

    /**
     * Creates a new object and stuff the initial parameters
     */	
	public PstAbstractObject create(PstUserAbstractObject userObj, String owner, String relPath,
			String ext, String projIdS, String attType)
		throws PmpObjectCreationException, PmpInternalException
    {
		return create(userObj, owner, relPath, ext, projIdS, attType, null, null);
    }

    /**
     * Creates a new object and stuff the initial parameters
     */	
	public PstAbstractObject create(PstUserAbstractObject userObj, String owner, String relPath,
			String ext, String projIdS, String attType, String deptName)
		throws PmpObjectCreationException, PmpInternalException
    {
		return create(userObj, owner, relPath, ext, projIdS, attType, deptName, null);
    }
	public PstAbstractObject create(PstUserAbstractObject userObj, String owner, String relPath,
			String ext, String projIdS, String attType, String deptName, String fileName)
		throws PmpObjectCreationException, PmpInternalException
    {
		attachment att = null;

		if (DEF_SEC_LEVEL < 0)
		{
			String s = Util.getPropKey("pst", "DEFAULT_SEC_LEVEL");
			if (s!=null && s.trim().length()>0) DEF_SEC_LEVEL = Integer.parseInt(s);
		}

		try
		{
			att = new attachment(userObj, m_organization);
			Date dt = new Date();
			att.setAttribute("Owner", owner);
			att.setAttribute("Location", relPath);
			att.setAttribute("CreatedDate", dt);
			att.setAttribute("LastUpdatedDate", dt);
			att.setAttribute("Frequency", new Integer(0));
			att.setAttribute("FileExt", ext);
			att.setAttribute("ProjectID", projIdS);
			att.setAttribute("Type", attType);		// see attachment.java for type
			att.setAttribute("SecurityLevel", new Integer(DEF_SEC_LEVEL));
			att.setAttribute("DepartmentName", deptName);		// @ECC011707
			att.setAttribute("Name", fileName);					// for Google need to store fileName
			commit(att);
			
			// add file to index or update using thread to index
			if (!relPath.toLowerCase().startsWith("http"))
			{
				// don't index if it is a remote server file like Google docs
				IndexScheduler isThread = new IndexScheduler(IndexScheduler.UPDATE, relPath, String.valueOf(att.getObjectId()));
				isThread.start();
			}
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new attachment");
		}

		return att;
    }



    /**
     *
     * Obtain a attachment object from database.
     * @param userObj  PstUserAbstractObject requesting a attachment object.
     * @param objectId Object id of the attachment object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a attachment object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectId);
    }//End get

    /**
     *
     * Obtain a attachment object from database.
     * @param session  An OmsSession.
     * @param objectId Object id of the attachment object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a attachment object.
     */
    PstAbstractObject get(OmsSession session, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session,objectId);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in attachment organization.");
            }

            //Return a attachment object
            return new attachment(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain a attachment object from the database.
     * @param userObj  A PstUserAbstractObject.
     * @param objectName Object name of the attachment object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a attachment object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(),objectName);
    }//End get

    /**
     *
     * Obtain a attachment object from the database.
     * @param session  An OmsSession.
     * @param objectName Object name of the attachment object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a attachment object.
     */
    PstAbstractObject get(OmsSession session, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session, super.m_organization, objectName);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in attachment organization.");
            }
            //Return a attachment object
            return new attachment(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of attachment objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the attachment objects.
     * @param objectIds Object ids in an int array of all attachment objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a attachment object.
     *   <b>NOTE:</b>  The arrays of attachment will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectIds);
    }//End get

    /**
     *
     * Obtain an array of attachment objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the attachment objects.
     * @param objectIds Object ids in an Integer array of all attachment objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a attachment object.
     *   <b>NOTE:</b>  The arrays of attachment will be sorted by object ids,
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
     * Obtain a Company object based on a set of attachment ids.
     * Obtain an array of attachment objects based on a set of specified object ids.
     * @param session  PstUserAbstractObject requesting the attachment objects.
     * @param objectIds Object ids of all attachment objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a attachment object.
     *   <b>NOTE:</b>  The arrays of attachment will be sorted by object ids,
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
                    return new attachment[0];
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

            attachment [] result = new attachment[newCount];

            for(int i=0; i<newCount; i++)
            {
                OmsMember member = (OmsMember) memList.get(i);
                //Return a attachment object
                result[i] = new attachment(member);

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
     * Obtain an array of attachment objects based on a set of specified attachment member names.
     * @param userObj  PstUserAbstractObject requesting the attachment objects.
     * @param objectNames Object names of all attachment objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a attachment object.
     *   <b>NOTE:</b>  The arrays of attachment will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectNames);
    }//End get

    /**
     *
     * Obtain an array of attachment objects based on a set of specified attachment member names.
     * @param session  PstUserAbstractObject requesting the attachment objects.
     * @param objectNames Object names of all attachment objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a attachment object.
     *   <b>NOTE:</b>  The arrays of attachment will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        int count = objectNames.length;
        if(count <1)
        {
                    return new attachment[0];
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

        attachment [] newResult = new attachment[newCount];
        for(int i=0; i<newCount; i++)
        {
            newResult[i] = (attachment) result.get(i);
        }

        return newResult;

    }//End get

    /**
     *
     * Delete the member from the database.
     * @param dataObject The attachment object to delete permanently.
     * @exception PmpDeleteObjectException Could not delete the specified object.
     */
    public void delete(PstAbstractObject dataObject)
        throws PmpDeleteObjectException
    {
    	// @AGQ062806 Remove attachment from index
    	String fileLocation = null;
    	try {
    		fileLocation = (String)dataObject.getAttribute(attachment.LOCATION)[0];
    	} catch (PmpException e) {}
    	if (fileLocation != null) {
	    	if(!mod.se.IndexBuilder.delete(fileLocation, String.valueOf(dataObject.getObjectId())))
				System.out.println("AttObjId: " + dataObject.getObjectId() + " cannot be found from index");
    	}
        ((attachment)dataObject).delete();

    }//End delete

    /**
     *
     * Save the member to the database.
     * @param dataObject The attachment object to save.
     * @exception PmpCommitObjectException Could not save the specified object.
     */
    public void commit(PstAbstractObject dataObject)
        throws PmpCommitObjectException
    {
        ((attachment)dataObject).save();

    }//End commit

    /**
     *
     * Refresh the member. Currently, not implemented.
     * @param dataObject The attachment object to refresh.
     */
    public void refresh(PstAbstractObject dataObject)
    {
        ((attachment)dataObject).refresh();

    }//End refresh



    /**
     * Obtain a List of attachment objects that belongs to the attachment.
     *
     * @param userObj - PstUserAbstractObject requesting the attachment objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of attachment objects that is own by this user.
     *
     */
    public PstAbstractObject [] getAllattachment(PstUserAbstractObject userObj)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		String expr = "(om_acctname='%')";

		int id[] = this.findId(userObj.getSession(), expr);

		if (id == null)
			return null;

		PstAbstractObject objArray[] = this.get(userObj, id);

        return objArray;
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

    public attachment updateFrequency(PstUserAbstractObject userObj, String location) 
    	throws PmpException {
    	attachment attObj = null;
    	if (userObj != null && location != null) {
    		String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
    		// TODO: too many replaceAll functions need to rethink algorithm
    		location = location.replace(repository, "");
    		location = location.replaceAll("\\'", "\\\\'");
    		location = location.replaceAll("\\\\", "/");
    		if (location.indexOf("/") != 0)
    		{
    			if (location.length()>2 && location.charAt(1)!=':')
    				location = "/" + location;
    		}
    		String expr = "Location='" + location + "'"; 		
    		int [] intArr = findId(userObj, expr);
    		if (intArr.length > 0)
    			attObj = updateFrequency(userObj, intArr[0]);
    		else
    			l.error("Could not find attachment object with location: " + location);
    		if (intArr.length > 1)
    			l.error("Duplicate entry for attachment id: "
    					+ intArr.toString() + " with location: " + location);
    	}
    	else
    		l.warn("UpdateFrequency called with null variables");
    	return attObj;
    }
    
    public attachment updateFrequency(PstUserAbstractObject userObj, int objId) 
		throws PmpException {
    	if (userObj != null && objId > -1) {
    		attachment att = (attachment)get(userObj, objId);
    		updateFrequency(userObj, att);
    		return att;
    	}
    	else {
    		l.warn("UpdateFrequency called with null variables");
    		return null;
    	}
    }
    
    public void updateFrequency(PstUserAbstractObject userObj, attachment att) 
		throws PmpException {
    	if (userObj != null && att != null) {
    		String userIdS = String.valueOf(userObj.getObjectId());
    		Object obj = att.getAttribute("Frequency")[0];
    		Integer frequency = (obj!=null)?(Integer)obj:new Integer(0);
    		frequency = new Integer(frequency.intValue()+1);
    		att.setAttribute("Frequency", frequency);
       		att.setAttribute("ViewBy", Util2.visited((String)att.getAttribute("ViewBy")[0], userIdS, MAX_VIEWBY));
       		att.setAttribute("LastAccessDate", new Date());
    		commit(att);
    	}
    	else
    		l.warn("UpdateFrequency called with null variables");
    }

	public static void sortByName(Object [] oArr, boolean ignoreCase)
	{
		// for folder, the name is "peace$C:/Doc/Company", here it will be changed to "(peace)C:/Doc/Company"
		// just for comparison
		attachment o1, o2;
		String v1, v2;
		String n1, n2;
		boolean swap;
		int result;
		do
		{
			swap = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (attachment)oArr[i];
				o2 = (attachment)oArr[i+1];
				try
				{
					n1 = o1.getFileName();
					if (n1!=null && n1.indexOf('$')!=-1)
						n1 = "(" + n1.replace("$", ")");
					n2 = o2.getFileName();
					if (n2!=null && n2.indexOf('$')!=-1)
						n2 = "(" + n2.replace("$", ")");
					
					v1 = (n1 != null)?n1:"";
					v2 = (n2 != null)?n2:"";				
					
					if (ignoreCase) {
						result = v1.compareToIgnoreCase(v2);
					}
					else
						result = v1.compareTo(v2);
					
					if (result > 0)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}

}//End class attachmentManager
