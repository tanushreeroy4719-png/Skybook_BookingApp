<%@ include file="../common/header.jsp" %>

<div class="card card-skybook p-4">
    <h4 class="mb-3">Add Flight</h4>
    <c:if test="${empty fleet}">
        <div class="alert alert-warning">You have no aircraft yet — ask an admin to add one for your airline before publishing flights.</div>
    </c:if>
    <c:if test="${not empty fleet}">
        <form method="post" action="${pageContext.request.contextPath}/airline/flights/add" class="row g-3">
            <div class="col-md-6">
                <label class="form-label">Aircraft</label>
                <select class="form-select" name="aircraftId" required>
                    <c:forEach var="ac" items="${fleet}">
                        <option value="${ac.aircraftId}">#${ac.aircraftId} — ${ac.aircraftModel} (${ac.registrationNo}, ${ac.totalSeats} seats)</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label">Flight Type</label>
                <select class="form-select" name="flightType" required>
                    <option value="National">National</option>
                    <option value="International">International</option>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label">Category</label>
                <select class="form-select" name="flightCategory" id="flightCategory" required onchange="toggleConnecting()">
                    <option value="Direct">Direct</option>
                    <option value="Connecting">Connecting</option>
                </select>
            </div>

            <div class="col-md-6">
                <label class="form-label">Departure Airport</label>
                <select class="form-select" name="depAirport" required>
                    <c:forEach var="a" items="${airports}"><option value="${a.airportCode}">${a.city} — ${a.airportCode}</option></c:forEach>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label">Arrival Airport</label>
                <select class="form-select" name="arrAirport" required>
                    <c:forEach var="a" items="${airports}"><option value="${a.airportCode}">${a.city} — ${a.airportCode}</option></c:forEach>
                </select>
            </div>

            <div class="col-md-6">
                <label class="form-label">Departure Time</label>
                <input class="form-control" type="datetime-local" name="depTime" required>
            </div>
            <div class="col-md-6">
                <label class="form-label">Arrival Time</label>
                <input class="form-control" type="datetime-local" name="arrTime" required>
            </div>

            <div class="col-md-4">
                <label class="form-label">Base Price (&#8377;)</label>
                <input class="form-control" type="number" step="0.01" min="0" name="basePrice" required>
            </div>
            <div class="col-md-4">
                <label class="form-label">State Tax (&#8377;)</label>
                <input class="form-control" type="number" step="0.01" min="0" name="stateTax" required>
            </div>
            <div class="col-md-4" id="connectingWrap" style="display:none">
                <label class="form-label">Connecting Flight ID</label>
                <input class="form-control" type="number" name="connectingFlightId">
            </div>

            <div class="col-12">
                <button class="btn btn-sb-primary" type="submit">Add Flight</button>
            </div>
        </form>
    </c:if>
</div>

<script>
    function toggleConnecting() {
        var cat = document.getElementById('flightCategory').value;
        document.getElementById('connectingWrap').style.display = (cat === 'Connecting') ? 'block' : 'none';
    }
</script>

<%@ include file="../common/footer.jsp" %>
