<%@ include file="../common/header.jsp" %>

<h4 class="mb-3">Bookings on My Flights</h4>

<c:if test="${empty bookings}">
    <div class="card card-skybook p-4">No bookings yet.</div>
</c:if>

<c:forEach var="b" items="${bookings}">
    <div class="card card-skybook p-3 mb-3">
        <div class="row align-items-center">
            <div class="col-md-4">
                <div class="fw-bold">${b.flightInfo}</div>
                <div class="text-muted small">Booking #${b.bookingId} &middot; ${b.bookingDateFormatted}</div>
            </div>
            <div class="col-md-4">${b.passengerName}</div>
            <div class="col-md-4 text-end">
                <span class="status-pill status-${b.status}">${b.status}</span>
            </div>
        </div>
    </div>
</c:forEach>

<%@ include file="../common/footer.jsp" %>
