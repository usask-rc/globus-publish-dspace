/**
 * This file is a modified version of a DSpace file.
 * All modifications are subject to the following copyright and license.
 * 
 * Copyright 2016 University of Chicago. All Rights Reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.handle;

import java.sql.SQLException;
import java.util.Collections;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

import net.handle.hdllib.Encoder;
import net.handle.hdllib.HandleException;
import net.handle.hdllib.HandleStorage;
import net.handle.hdllib.HandleValue;
import net.handle.hdllib.ScanCallback;
import net.handle.hdllib.Util;
import net.handle.util.StreamTable;

import org.apache.log4j.Logger;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Context;

/**
 * Extension to the CNRI Handle Server that translates requests to resolve
 * handles into DSpace API calls. The implementation simply stubs out most of
 * the methods, and delegates the rest to the
 * {@link org.dspace.handle.HandleManager}. This only provides some of the
 * functionality (namely, the resolving of handles to URLs) of the CNRI
 * HandleStorage interface.
 *
 * <p>
 * This class is intended to be embedded in the CNRI Handle Server. It conforms
 * to the HandleStorage interface that was delivered with Handle Server version
 * 5.2.0.
 * </p>
 *
 * @author Peter Breton
 * @version $Revision$
 */
public class HandlePlugin implements HandleStorage
{
    /** log4j category */
    private static Logger log = Logger.getLogger(HandlePlugin.class);

    /**
     * Constructor
     */
    public HandlePlugin()
    {
    }

    ////////////////////////////////////////
    // Non-Resolving methods -- unimplemented
    ////////////////////////////////////////

    /**
     * HandleStorage interface method - not implemented.
     */
    public void init(StreamTable st) throws Exception
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called init (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void setHaveNA(byte[] theHandle, boolean haveit)
            throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called setHaveNA (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void createHandle(byte[] theHandle, HandleValue[] values)
            throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called createHandle (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public boolean deleteHandle(byte[] theHandle) throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called deleteHandle (not implemented)");
        }

        return false;
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void updateValue(byte[] theHandle, HandleValue[] values)
            throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called updateValue (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void deleteAllRecords() throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called deleteAllRecords (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void checkpointDatabase() throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called checkpointDatabase (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void shutdown()
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called shutdown (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void scanHandles(ScanCallback callback) throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called scanHandles (not implemented)");
        }
    }

    /**
     * HandleStorage interface method - not implemented.
     */
    public void scanNAs(ScanCallback callback) throws HandleException
    {
        // Not implemented
        if (log.isInfoEnabled())
        {
            log.info("Called scanNAs (not implemented)");
        }
    }

    ////////////////////////////////////////
    // Resolving methods
    ////////////////////////////////////////

    /**
     * Return the raw values for this handle. This implementation returns a
     * single URL value.
     *
     * @param theHandle
     *            byte array representation of handle
     * @param indexList
     *            ignored
     * @param typeList
     *            ignored
     * @return A byte array with the raw data for this handle. Currently, this
     *         consists of a single URL value.
     * @exception HandleException
     *                If an error occurs while calling the Handle API.
     */
    public byte[][] getRawHandleValues(byte[] theHandle, int[] indexList,
            byte[][] typeList) throws HandleException
    {
        if (log.isInfoEnabled())
        {
            log.info("Called getRawHandleValues");
        }

        Context context = null;

        try
        {
            if (theHandle == null)
            {
                throw new HandleException(HandleException.INTERNAL_ERROR);
            }

            String handle = Util.decodeString(theHandle);

            context = new Context();

            String url = HandleManager.resolveToURL(context, handle);

            if (url == null)
            {
                throw new HandleException(HandleException.HANDLE_DOES_NOT_EXIST);
            }

            HandleValue value = new HandleValue();

            value.setIndex(100);
            value.setType(Util.encodeString("URL"));
            value.setData(Util.encodeString(url));
            value.setTTLType((byte) 0);
            value.setTTL(100);
            value.setTimestamp(100);
            value.setReferences(null);
            value.setAdminCanRead(true);
            value.setAdminCanWrite(false);
            value.setAnyoneCanRead(true);
            value.setAnyoneCanWrite(false);

            List<HandleValue> values = new LinkedList<HandleValue>();

            values.add(value);

            byte[][] rawValues = new byte[values.size()][];

            for (int i = 0; i < values.size(); i++)
            {
                HandleValue hvalue = values.get(i);

                rawValues[i] = new byte[Encoder.calcStorageSize(hvalue)];
                Encoder.encodeHandleValue(rawValues[i], 0, hvalue);
            }

            return rawValues;
        }
        catch (HandleException he)
        {
            throw he;
        }
        catch (Exception e)
        {
            if (log.isDebugEnabled())
            {
                log.debug("Exception in getRawHandleValues", e);
            }

            // Stack loss as exception does not support cause
            throw new HandleException(HandleException.INTERNAL_ERROR);
        }
        finally
        {
            if (context != null)
            {
                try
                {
                    context.complete();
                }
                catch (SQLException sqle)
                {
                }
            }
        }
    }

    /**
     * Return true if we have this handle in storage.
     *
     * @param theHandle
     *            byte array representation of handle
     * @return True if we have this handle in storage
     * @exception HandleException
     *                If an error occurs while calling the Handle API.
     */
    public boolean haveNA(byte[] theHandle) throws HandleException
    {
        if (log.isInfoEnabled())
        {
            log.info("Called haveNA");
        }

        /*
         * Naming authority Handles are in the form: 0.NA/1721.1234
         *
         * 0.NA is basically the naming authority for naming authorities. For
         * this simple implementation, we will just check that the prefix
         * configured in dspace.cfg is the one in the request, returning true if
         * this is the case, false otherwise.
         *
         * FIXME: For more complex Handle situations, this will need enhancing.
         */

        // This parameter allows the dspace handle server to be capable of having multiple
        // name authorities assigned to it. So long as the handle table the alternative prefixes
        // defined the dspace will answer for those handles prefixes. This is not ideal and only
        // works if the dspace instances assumes control over all the items in a prefix, but it
        // does allow the admin to merge together two previously separate dspace instances each
        // with their own prefixes and have the one instance handle both prefixes. In this case
        // all new handle would be given a unified prefix but all old handles would still be
        // resolvable.
        if (ConfigurationManager.getBooleanProperty("handle.plugin.checknameauthority",true))
        {
	        // First, construct a string representing the naming authority Handle
	        // we'd expect.
	        String expected = "0.NA/" + HandleManager.getPrefix();

	        // Which authority does the request pertain to?
	        String received = Util.decodeString(theHandle);

	        // Return true if they match
	        return expected.equals(received);
        }
        else
        {
        	return true;
        }
    }

    /**
     * Return all handles in local storage which start with the naming authority
     * handle.
     *
     * @param theNAHandle
     *            byte array representation of naming authority handle
     * @return All handles in local storage which start with the naming
     *         authority handle.
     * @exception HandleException
     *                If an error occurs while calling the Handle API.
     */
    public Enumeration getHandlesForNA(byte[] theNAHandle)
            throws HandleException
    {
        String naHandle = Util.decodeString(theNAHandle);

        if (log.isInfoEnabled())
        {
            log.info("Called getHandlesForNA for NA " + naHandle);
        }

        Context context = null;

        try
        {
            context = new Context();

            List<String> handles = HandleManager.getHandlesForPrefix(context, naHandle);
            List<byte[]> results = new LinkedList<byte[]>();

            for (Iterator<String> iterator = handles.iterator(); iterator.hasNext();)
            {
                String handle = iterator.next();

                // Transforms to byte array
                results.add(Util.encodeString(handle));
            }

            return Collections.enumeration(results);
        }
        catch (SQLException sqle)
        {
            if (log.isDebugEnabled())
            {
                log.debug("Exception in getHandlesForNA", sqle);
            }

            // Stack loss as exception does not support cause
            throw new HandleException(HandleException.INTERNAL_ERROR);
        }
        finally
        {
            if (context != null)
            {
                try
                {
                    context.complete();
                }
                catch (SQLException sqle)
                {
                }
            }
        }
    }

    /* (non-Javadoc)
     * @see net.handle.hdllib.HandleStorage#init(net.cnri.util.StreamTable)
     */
    @Override
    public void init(net.cnri.util.StreamTable configTable) throws Exception
    {
        // TODO Auto-generated method stub

    }
}
