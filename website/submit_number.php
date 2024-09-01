

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$phone_number = $_POST['phone_number'];

$stmt = $conn->prepare("INSERT INTO calls (phone_number) VALUES (?)");
$stmt->bind_param("s", $phone_number);

if($stmt->execute()) {
    echo "New record created successfully";
} else {
    echo "Error: " . $stmt->error;
}

$stmt->close();
$conn->close();
?>
