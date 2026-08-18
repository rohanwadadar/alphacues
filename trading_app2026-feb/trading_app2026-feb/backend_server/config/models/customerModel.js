const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

const customerRoutes = require("./routes/customers");
app.use("/customers", customerRoutes);

app.listen(3000, () => console.log("🚀 Backend running on port 3000"));
