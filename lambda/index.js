const AWS = require('aws-sdk');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const dynamo = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();

const USERS_TABLE = process.env.USERS_TABLE;
const BUCKET_NAME = process.env.BUCKET_NAME;
const JWT_SECRET = process.env.JWT_SECRET;

exports.handler = async (event) => {
  const path = event.rawPath || event.path; // fallback for legacy support
  const method = event.requestContext?.http?.method || event.httpMethod;

  try {
    if (path === "/register" && method === "POST") return await register(event);
    if (path === "/login" && method === "POST") return await login(event);
    if (path === "/list-files" && method === "GET") return await listFiles(event);
    if (path === "/get-upload-url" && method === "POST") return await getUploadUrl(event);

    return respond(404, { message: "Not Found" });
  } catch (err) {
    console.error("Unhandled error:", err);
    return respond(500, { message: "Internal Server Error" });
  }
};

// REGISTER
async function register(event) {
  const { username, password } = safeJson(event.body);

  if (!username || !password) {
    return respond(400, { message: "Username and password required" });
  }

  const hashed = await bcrypt.hash(password, 10);

  try {
    await dynamo.put({
      TableName: USERS_TABLE,
      Item: { username, passwordHash: hashed },
      ConditionExpression: "attribute_not_exists(username)",
    }).promise();

    return respond(201, { message: "User registered" });
  } catch (err) {
    if (err.code === "ConditionalCheckFailedException") {
      return respond(400, { message: "User already exists" });
    }

    console.error("Register error:", err);
    return respond(500, { message: "Error registering user" });
  }
}

// LOGIN
async function login(event) {
  const { username, password } = safeJson(event.body);

  if (!username || !password) {
    return respond(400, { message: "Username and password required" });
  }

  const result = await dynamo.get({
    TableName: USERS_TABLE,
    Key: { username },
  }).promise();

  const user = result.Item;

  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return respond(401, { message: "Invalid credentials" });
  }

  const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: "2h" });
  return respond(200, { token });
}

// LIST FILES
async function listFiles(event) {
  const username = verifyToken(event);
  if (!username) return respond(401, { message: "Unauthorized" });

  const prefix = `users/${username}/`;

  try {
    const s3Data = await s3.listObjectsV2({ Bucket: BUCKET_NAME, Prefix: prefix }).promise();
    const files = (s3Data.Contents || []).map(item => ({
      name: item.Key.split("/").pop(),
      url: s3.getSignedUrl("getObject", {
        Bucket: BUCKET_NAME,
        Key: item.Key,
        Expires: 3600,
      }),
    }));

    return respond(200, files);
  } catch (err) {
    console.error("List files error:", err);
    return respond(500, { message: "Failed to list files" });
  }
}

// GET UPLOAD URL
async function getUploadUrl(event) {
  const username = verifyToken(event);
  if (!username) return respond(401, { message: "Unauthorized" });

  const { filename } = safeJson(event.body);

  if (!filename) return respond(400, { message: "Filename required" });

  const objectKey = `users/${username}/${filename}`;
  const uploadUrl = s3.getSignedUrl("putObject", {
    Bucket: BUCKET_NAME,
    Key: objectKey,
    Expires: 3600,
  });

  return respond(200, { url: uploadUrl, key: objectKey });
}

// Helpers

function verifyToken(event) {
  const token = event.headers?.Authorization?.replace("Bearer ", "");
  if (!token) return null;

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    return payload.username;
  } catch (err) {
    console.error("Invalid token:", err);
    return null;
  }
}

function safeJson(jsonString) {
  try {
    return JSON.parse(jsonString || "{}");
  } catch (e) {
    return {};
  }
}

function respond(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "*",
      "Access-Control-Allow-Methods": "*",
    },
    body: JSON.stringify(body),
  };
}