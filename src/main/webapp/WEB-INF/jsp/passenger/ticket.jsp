<%@ include file="../common/header.jsp" %>

<div class="alert alert-success">Booking confirmed! Your ticket is below.</div>

<div class="card ticket-card p-4 mb-4">
    <div class="row">
        <div class="col-md-8">
            <h4 class="mb-1">${ticket.airlineName}</h4>
            <div class="text-muted mb-3">${ticket.flightRoute} &middot; ${ticket.departureTime}</div>

            <div class="row g-3">
                <div class="col-6"><div class="text-muted small">Passenger</div><div class="fw-bold">${ticket.passengerName}</div></div>
                <div class="col-6"><div class="text-muted small">PNR</div><div class="fw-bold">${ticket.pnr}</div></div>
                <div class="col-6"><div class="text-muted small">Seat</div><div class="fw-bold">${ticket.seatNumber} (${ticket.seatClass} / ${ticket.seatPosition})</div></div>
                <div class="col-6"><div class="text-muted small">Booking ID</div><div class="fw-bold">#${bookingId}</div></div>
            </div>
        </div>
        <div class="col-md-4 text-md-end">
            <div class="text-muted small">Total Paid</div>
            <div class="fs-3 fw-bold">&#8377;<fmt:formatNumber value="${ticket.totalCost}" maxFractionDigits="0"/></div>
            <c:if test="${not empty payment}">
                <div class="status-pill status-${payment.paymentStatus}">${payment.paymentStatus}</div>
                <div class="text-muted small mt-1">via ${payment.paymentMethod}</div>
            </c:if>
        </div>
    </div>
</div>

<a href="${pageContext.request.contextPath}/passenger/bookings" class="btn btn-sb-primary">Go to My Bookings</a>
<button class="btn btn-outline-secondary" onclick="window.print()">Print Ticket</button>

<%@ include file="../common/footer.jsp" %>
