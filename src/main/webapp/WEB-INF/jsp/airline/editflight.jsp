<%@ include file="../common/header.jsp" %>

<div class="card card-skybook p-4">
    <h4 class="mb-3">Edit Flight #${flight.flightId}</h4>
    <p class="text-muted">${flight.departureAirportId} &rarr; ${flight.arrivalAirportId} &middot; ${flight.aircraftModel}</p>

    <form method="post" action="${pageContext.request.contextPath}/airline/flights/edit" class="row g-3">
        <input type="hidden" name="flightId" value="${flight.flightId}">
        <div class="col-md-6">
            <label class="form-label">Departure Time</label>
            <input class="form-control" type="datetime-local" name="depTime" value="${flight.departureTime}" required>
        </div>
        <div class="col-md-6">
            <label class="form-label">Arrival Time</label>
            <input class="form-control" type="datetime-local" name="arrTime" value="${flight.arrivalTime}" required>
        </div>
        <div class="col-md-6">
            <label class="form-label">Base Price (&#8377;)</label>
            <input class="form-control" type="number" step="0.01" min="0" name="basePrice" value="${flight.basePrice}" required>
        </div>
        <div class="col-12">
            <button class="btn btn-sb-primary" type="submit">Save Changes</button>
            <a class="btn btn-outline-secondary" href="${pageContext.request.contextPath}/airline/dashboard">Cancel</a>
        </div>
    </form>
</div>

<%@ include file="../common/footer.jsp" %>
