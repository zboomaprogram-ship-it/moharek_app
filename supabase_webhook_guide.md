# Guide: Manually Creating Database Webhooks in Supabase Dashboard

Since we removed the `pg_net` extension (which was causing issues), you need to manually configure the Database Webhook in your Supabase Dashboard to restore push notifications for calls.

Follow these step-by-step instructions:

---

### Step 1: Go to Database Webhooks
1. Open your **Supabase Dashboard**.
2. In the left sidebar, click on **Database** (the database icon).
3. Under the Database menu, select **Webhooks**.
4. Click **Enable Database Webhooks** if it is not already enabled.

---

### Step 2: Create the Call Signals Webhook
1. Click **Create Webhook** (or **Add Webhook**).
2. Fill in the following details:
   - **Name:** `on_call_signal_created`
   - **Table:** Select `call_signals` (schema: `public`)
   - **Events:** Check **Insert** (only trigger on insertion)
3. Under **Webhook Service**, choose **Supabase Edge Function**.
4. Configure the Edge Function call:
   - **Method:** `POST`
   - **Edge Function:** Select `send-notification` from the dropdown.
     - *If your Supabase project isn't displaying it, choose **HTTP URL** and paste: `https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/send-notification`*
   - **Timeout:** `5000` ms (default)
5. Under **HTTP Headers**, click **Add Header** to add the Authorization header:
   - **Name:** `Authorization`
   - **Value:** `Bearer <YOUR_SUPABASE_SERVICE_ROLE_KEY>`
     - *To find your service role key: Go to **Project Settings** -> **API** -> Copy the `service_role` key (jwt).*
6. Click **Save** / **Create Webhook**.

---

### Step 3: (Optional but recommended) Verify Webhook Status
1. To make sure notifications are sent, try placing a call from the client application.
2. In the Webhooks page, click on your newly created webhook `on_call_signal_created`.
3. Scroll down to the **History** section to see execution logs and verify they show `200 OK`.
