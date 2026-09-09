from fastapi import FastAPI, HTTPException
import mysql.connector 


app = FastAPI()

# Function to connect to MySQL database
def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",          # Change to your MySQL username
        password="Dev$123456",  # Change to your MySQL password
        database="my_database" # Change to your database name
    )

# ----------------------------
# 1. GET ALL PATIENTS (Retrieve)
# ----------------------------
@app.get("/patients")
def get_patients():
    db = get_db()
    cursor = db.cursor(dictionary=True) # dictionary=True returns data as JSON key-value pairs
    
    cursor.execute("SELECT * FROM patients")
    results = cursor.fetchall()
    
    cursor.close()
    db.close()
    return results

# ----------------------------
# 2. ADD A NEW PATIENT (Insert)
# ------------------------- import Error

@app.post("/patients-direct")
def create_patient_catch(doctor_id: int, name: str, gender :str, age: int, emergency_contact: str):
    db = get_db()
    cursor = db.cursor()

    try:
        query = """
            INSERT INTO patients (doctor_id, name,gender, age, emergency_contact) 
            VALUES (%s, %s,%s, %s, %s)
        """
        cursor.execute(query, (doctor_id, name,gender, age, emergency_contact))
        db.commit()
        patient_id = cursor.lastrowid
        return {"message": "Patient created", "patient_id": patient_id}

    except Error as e:
        # MySQL Error 1452 indicates foreign key failure
        if e.errno == 1452:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid doctor_id {doctor_id}. Foreign key constraint failed."
            )
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        cursor.close()
        db.close()