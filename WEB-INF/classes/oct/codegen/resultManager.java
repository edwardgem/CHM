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
//  File:   resultManager.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2003
//  Description:
//    This is a class that represent the container of result classes.
//
//  Modification:
//		@03.18.2003aFCE File created by FastPath
//
/////////////////////////////////////////////////////////////////////
//
// resultManager.java : For result object container manipulation
//

package oct.codegen;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

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

 /**
  *
  * <b>General Description:</b>  resultManager extends PstManager.  This class
  * manages all result objects such as creating, retrieving, saving, and
  * deleting result objects.
  *
  * resultManager can only instantiated through the getInstance() method.
  *
  *
  * <b>Class Dependencies:</b>
  *   oct.codegen.result
  *   oct.pst.PstUserAbstractObject
  *   oct.pst.PstUserManager
  *   oct.pst.PstAbstractObject
  *   oct.pst.PstManager
  *
  *
  * <b>Miscellaneous:</b> None.
  *
  */


public class resultManager extends oct.pst.PstManager

{
    public static final String NAME = "result";     // The orgname of Object result
    public static final String CLASSNAME = "oct.codegen.result";     // The className of Object result

    private static resultManager manager = null;


    /**
     * Construct an empty result object
     * @param user A PstUserAbstractObject.
     */
    private resultManager(PstUserAbstractObject user)
        throws PmpManagerCreationException
    {
        super(user, NAME, CLASSNAME);
    }

    /**
     * Instantiates a resultManager object.
     * @return A resultManager.
     */
    public static resultManager getInstance()
        throws PmpManagerCreationException, PmpInternalException
    {
        if(manager == null)
        {
            manager = new resultManager(PstSystem.getInstance());
        }
        return manager;
    }//End getInstance


    /**
     * Create a new result object.
     * @param user The PstUserAbstractObject who is requesting to create a result.
     * @param type The type of result to create.<br>
     * @param resultName The name of the result.
     *
     * @exception PmpObjectCreationException There was an error creating the result.
     * @exception PmpIllegalTypeException The specified compnaytype is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a result object.
     */
    public PstAbstractObject create(PstUserAbstractObject user, String resultName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        return create(user.getSession(), resultName);
    }//End create

    /**
     * Create a new result object.
     * @param session An OmsSession.
     * @param type The type of result to create.<br>
     * @param resultName The name of the result.
     * @exception PmpObjectCreationException There was an error creating the result.
     * @exception PmpIllegalTypeException The specified result type is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a result object.
     */
    PstAbstractObject create(OmsSession session, String resultName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        result result = null;
        if(resultName == null || resultName.length() == 0)
        {
            throw new PmpObjectCreationException("The result name cannot be empty.");
        }

        try
        {

            result = new result(session,m_organization, resultName);
            return result;
        }
        catch(PmpException pe)
        {
            if(result != null)
            {
                try
                {
                    delete(result);
                }
                catch(Exception e1)
                {
                }
            }
            throw new PmpObjectCreationException("Error creating result object:" + pe.toString());
        }
    }//End create


    /**
     * create creates a new user of the specified type
     * @param user - the user asking to create a user
     * @param type - the type of user to create (i.e. SELLER, BUYER_ADMIN, etc.)  see public static constants
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject user, String memberName, String password)
    	throws PmpObjectCreationException, PmpInternalException
    {
		result newUser = null;
		try
		{
			newUser = new result(user, m_organization, memberName, password);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new result");
		}

		return newUser;
    }



    /**
     * create creates a new object with generated member name
     * @param user - the user asking to create a user
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject user)
    	throws PmpObjectCreationException, PmpInternalException
    {
		result newUser = null;
		try
		{
			newUser = new result(user, m_organization);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new result");
		}

		return newUser;
    }




    /**
     *
     * Obtain a result object from database.
     * @param user  PstUserAbstractObject requesting a result object.
     * @param objectId Object id of the result object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a result object.
     */
    public PstAbstractObject get(PstUserAbstractObject user, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(), objectId);
    }//End get

    /**
     *
     * Obtain a result object from database.
     * @param session  An OmsSession.
     * @param objectId Object id of the result object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a result object.
     */
    PstAbstractObject get(OmsSession session, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session,objectId);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in result organization.");
            }

            //Return a result object
            return new result(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain a result object from the database.
     * @param user  A PstUserAbstractObject.
     * @param objectName Object name of the result object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a result object.
     */
    public PstAbstractObject get(PstUserAbstractObject user, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(),objectName);
    }//End get

    /**
     *
     * Obtain a result object from the database.
     * @param session  An OmsSession.
     * @param objectName Object name of the result object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a result object.
     */
    PstAbstractObject get(OmsSession session, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session, super.m_organization, objectName);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in result organization.");
            }
            //Return a result object
            return new result(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of result objects based on a set of specified object ids.
     * @param user  PstUserAbstractObject requesting the result objects.
     * @param objectIds Object ids of all result objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a result object.
     *   <b>NOTE:</b>  The arrays of result will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject user, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(), objectIds);
    }//End get

    /**
     *
     * Obtain a Company object based on a set of result ids.
     * Obtain an array of result objects based on a set of specified object ids.
     * @param session  PstUserAbstractObject requesting the result objects.
     * @param objectIds Object ids of all result objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a result object.
     *   <b>NOTE:</b>  The arrays of result will be sorted by object ids,
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
                    return new result[0];
            }

            //OmsSession session = user.getSession();
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

            result [] result = new result[newCount];

            for(int i=0; i<newCount; i++)
            {
                OmsMember member = (OmsMember) memList.get(i);
                //Return a result object
                result[i] = new result(member);

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
     * Obtain an array of result objects based on a set of specified result member names.
     * @param session  PstUserAbstractObject requesting the result objects.
     * @param objectNames Object names of all result objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a result object.
     *   <b>NOTE:</b>  The arrays of result will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject user, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(), objectNames);
    }//End get

    /**
     *
     * Obtain an array of result objects based on a set of specified result member names.
     * @param session  PstUserAbstractObject requesting the result objects.
     * @param objectNames Object names of all result objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a result object.
     *   <b>NOTE:</b>  The arrays of result will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        int count = objectNames.length;
        if(count <1)
        {
                    return new result[0];
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

        result [] newResult = new result[newCount];
        for(int i=0; i<newCount; i++)
        {
            newResult[i] = (result) result.get(i);
        }

        return newResult;

    }//End get

    /**
     *
     * Delete the member from the database.
     * @param dataObject The result object to delete permanently.
     * @exception PmpDeleteObjectException Could not delete the specified object.
     */
    public void delete(PstAbstractObject dataObject)
        throws PmpDeleteObjectException
    {
        ((result)dataObject).delete();

    }//End delete

    /**
     *
     * Save the member to the database.
     * @param dataObject The result object to save.
     * @exception PmpCommitObjectException Could not save the specified object.
     */
    public void commit(PstAbstractObject dataObject)
        throws PmpCommitObjectException
    {
        ((result)dataObject).save();

    }//End commit

    /**
     *
     * Refresh the member. Currently, not implemented.
     * @param dataObject The result object to refresh.
     */
    public void refresh(PstAbstractObject dataObject)
    {
        ((result)dataObject).refresh();

    }//End refresh


    /**
     * Obtain a List of result objects based on on the user ID.
     *
     * @param user  PstUserAbstractObject requesting the result objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of result objects that is own by this user.
     *
     */
    public List getAllresult(PstUserAbstractObject user)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		List resultList = new ArrayList();
		String expr = "(Owner='" + user.getObjectName() + "')";

		int id[] = this.findId(user.getSession(), expr);

		if (id == null)
			return resultList;

		PstAbstractObject objArray[] = this.get(user, id);
		for(int i = 0; i < objArray.length; i++)
		{
			resultList.add((result)objArray[i]);
		}

        return resultList;
    }


    /**
     * Obtain a List of result objects that belongs to the result.
     *
     * @param projID - int value of a result ID.
     * @param user - PstUserAbstractObject requesting the result objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of result objects that is own by this user.
     *
     */
    public List getAllresult(PstUserAbstractObject user, int projID)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		List resultList = new ArrayList();
		String expr = "(Parent='" + projID + "')";

		int id[] = this.findId(user.getSession(), expr);

		if (id == null)
			return resultList;

		PstAbstractObject objArray[] = this.get(user, id);
		for(int i = 0; i < objArray.length; i++)
		{
			resultList.add((result)objArray[i]);
		}

        return resultList;
    }


    /**
     * Add a dynamic attribute to the purchase order object definition
     * @param <b> user </b> user object
     * @param <b> attObject </b> object contains information of the attribute to be added
     * @return a list of PstAttributeObject objects
     * @exception PmpAddAttributeException could not add attribute.
     * @exception PmpInternalException internal errors
     */
    public void addAttribute(PstUserAbstractObject user, String attributeName, boolean required)
        throws PmpInternalException
    {
        super.addAttribute(user, attributeName, required);
    }

    /**
     * Remove an attribute
     * @param <b> user </b> user object
     * @param <b> attname </b> name of the attribute to be deleted
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.
     */
    public void removeAttribute(PstUserAbstractObject user, String attName)
    	throws PmpInternalException, PmpAttributeNotFoundException, PmpInvalidAttributeException
    {
        super.removeAttribute(user,attName);
    }

    /**
     * Return a PstAttributeObject that contains information of the given attribute name,
     * including system and dynmaic attribute.
     * @param <b> user </b> user object
     * @param <b> attName </b> name of the attribure to be returned
     * @return a PstAttributeObject object
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.

    public PstAttributeObject getAttribute(PstUserAbstractObject user, String attName)
        throws PmpAttributeNotFoundException, PmpInternalException
    {
        PstAttributeObject attribData = super.getAttribute(user,attName);
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

    public static PstAbstractObject createBlog(PstUserAbstractObject u, String type, String targetIdS,
    		String idS, String content)
    	throws PmpException
    {
    	// create a blog of the corresponding type
    	Date now = new Date();
    	PstAbstractObject rObj = manager.create(u);
    	rObj.setAttribute("CreatedDate", now);
    	rObj.setAttribute("Creator", String.valueOf(u.getObjectId()));
      	rObj.setAttribute("Type", type);
        rObj.setAttribute("Attendee", targetIdS);	// userId or townId that receive this blog
        rObj.setAttribute("TaskID", idS);			// null or event id
    	rObj.setAttribute("Comment", content.getBytes());
    	manager.commit(rObj);
    	return rObj;
    }

}//End class resultManager
