<% request.setAttribute("fullPage", true); %>
<%@ include file="../common/header.jsp" %>
<div class="bk-band"><div class="container pb-3">
  <h1 class="text-white fw-bold">Find your next stay</h1>
  <p class="text-white fs-4 mb-4">Search deals on hotels, homes and much more...</p>
  <form method="get" action="${pageContext.request.contextPath}/passenger/stays" class="bk-search">
    <div class="bk-fields">
      <div class="bk-field"><small>Where are you going?</small>
        <select name="city" required><option value="">Select destination</option>
          <c:forEach var="ct" items="${cities}"><option ${ct == city ? 'selected' : ''}>${ct}</option></c:forEach></select></div>
      <div class="bk-field"><small>Check-in</small><input type="date" name="checkIn" value="${empty checkIn ? '2026-10-31' : checkIn}" required></div>
      <div class="bk-field"><small>Check-out</small><input type="date" name="checkOut" value="${empty checkOut ? '2026-11-07' : checkOut}" required></div>
      <div class="bk-field"><small>Guests</small><select name="guests"><option>1</option><option ${guests=='2'?'selected':''}>2</option><option>3</option><option>4</option></select></div>
      <div class="bk-field"><small>Rooms</small><select name="rooms"><option>1</option><option ${rooms=='2'?'selected':''}>2</option><option>3</option></select></div>
      <button class="bk-go" type="submit">Search</button>
    </div>
  </form>
</div></div>
<div class="container mt-4">
    <c:if test="${not empty city}"><h4>${city}: ${fn:length(hotels)} properties found</h4></c:if>
  <c:forEach var="h" items="${hotels}">
    <div class="flight-card">
      <div class="hotel-img" style="background-image:url(${pageContext.request.contextPath}/images/city.svg)"></div>
      <div class="fc-main">
        <h5 class="mb-1">${h.HotelName} <span style="color:#febb02">${'★'}</span>${h.Stars}</h5>
        <div class="fc-sub">${h.Address} &middot; ${h.Amenities}</div>
        <p class="my-2">${h.Description}</p>
        <c:if test="${h.BreakfastIncluded}"><span class="bk-tag green">Breakfast included</span></c:if>
        <c:if test="${h.FreeCancellation}"><span class="bk-tag green">Free cancellation</span></c:if>
      </div>
      <div class="fc-side">
        <div><span class="bk-tag" style="background:var(--bk-navy);color:#fff;font-size:1rem">${h.Rating}</span><div class="fc-sub mt-1">Rating</div></div>
        <div class="text-end"><div class="fc-sub">per night</div>
          <div class="fc-price">INR<fmt:formatNumber value="${h.PricePerNight}" maxFractionDigits="0"/></div>
          <a class="btn-view mt-2" href="?id=${h.HotelID}&checkIn=${checkIn}&checkOut=${checkOut}&guests=${guests}&rooms=${rooms}">See availability</a></div>
      </div>
    </div>
  </c:forEach>
</div>
<%@ include file="../common/footer.jsp" %>
