<%@ include file="../common/header.jsp" %>

<c:if test="${not empty profile}">
    <div class="card card-skybook p-4 mb-4">
        <div class="row align-items-center">
            <div class="col-md-8">
                <h4 class="mb-1">${profile.airlineName} <span class="text-muted">(${profile.iataCode})</span></h4>
                <div class="text-muted small">${profile.country} &middot; ${profile.contactEmail}</div>
            </div>
            <div class="col-md-4 text-md-end">
                <span class="status-pill ${profile.active ? 'status-Confirmed' : 'status-Cancelled'}">${profile.active ? 'Active' : 'Deactivated'}</span>
            </div>
        </div>
    </div>
</c:if>

<c:if test="${!profile.active}">
    <div class="alert alert-warning">Your airline account has been deactivated by the administrator. You cannot add or edit flights until it is reactivated.</div>
</c:if>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="mb-0">My Flights</h5>
    <a class="btn btn-sb-accent" href="${pageContext.request.contextPath}/airline/flights/add">+ Add Flight</a>
</div>

<c:if test="${empty flights}">
    <div class="card card-skybook p-4 mb-4">No flights yet.</div>
</c:if>

<c:forEach var="f" items="${flights}">
    <div class="card flight-card mb-3 p-3">
        <div class="row align-items-center">
            <div class="col-md-1 text-muted">#${f.flightId}</div>
            <div class="col-md-4">
                <strong>${f.departureAirportId} → ${f.arrivalAirportId}</strong>
                <div class="text-muted small">${f.departureFormatted} &rarr; ${f.arrivalFormatted}</div>
            </div>
            <div class="col-md-2 text-muted small">${f.flightCategory} &middot; ${f.flightType}</div>
            <div class="col-md-2">&#8377;<fmt:formatNumber value="${f.totalPrice}" maxFractionDigits="0"/></div>
            <div class="col-md-1">${f.availableSeats} seats</div>
            <div class="col-md-2 text-end">
                <a class="btn btn-sm btn-outline-primary" href="${pageContext.request.contextPath}/airline/flights/edit?flightId=${f.flightId}">Edit</a>
                <form method="post" action="${pageContext.request.contextPath}/airline/flights/delete" style="display:inline"
                      onsubmit="return confirm('Remove flight #${f.flightId}? Any confirmed bookings will be cancelled.');">
                    <input type="hidden" name="flightId" value="${f.flightId}">
                    <button class="btn btn-sm btn-outline-danger" type="submit">Remove</button>
                </form>
            </div>
        </div>
    </div>
</c:forEach>

<h5 class="mt-4 mb-3">My Fleet</h5>
<c:if test="${empty fleet}">
    <div class="card card-skybook p-4">No aircraft registered yet. Ask an admin to add one for your airline.</div>
</c:if>
<c:if test="${not empty fleet}">
    <div class="table-responsive">
        <table class="table card-skybook bg-white">
            <thead><tr><th>Aircraft ID</th><th>Registration</th><th>Model</th><th>Seats</th><th>Status</th></tr></thead>
            <tbody>
            <c:forEach var="ac" items="${fleet}">
                <tr>
                    <td>${ac.aircraftId}</td>
                    <td>${ac.registrationNo}</td>
                    <td>${ac.aircraftModel}</td>
                    <td>${ac.totalSeats}</td>
                    <td>${ac.status}</td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</c:if>

<%@ include file="../common/footer.jsp" %>
