from collections import defaultdict
import time
from fastapi import HTTPException, Request
from functools import wraps

class RateLimiter:
    def __init__(self, requests_per_minute=60):
        self.requests_per_minute = requests_per_minute
        self.requests = defaultdict(list)
    
    def __call__(self, func):
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs):
            client_ip = request.client.host
            now = time.time()
            minute_ago = now - 60
            
            # Clean old requests
            self.requests[client_ip] = [
                req_time for req_time in self.requests[client_ip]
                if req_time > minute_ago
            ]
            
            # Check limit
            if len(self.requests[client_ip]) >= self.requests_per_minute:
                raise HTTPException(
                    status_code=429,
                    detail=f"Rate limit exceeded. Maximum {self.requests_per_minute} requests per minute."
                )
            
            # Add current request
            self.requests[client_ip].append(now)
            
            # Execute the function
            return await func(request, *args, **kwargs)
        return wrapper

# Create global rate limiter
rate_limiter = RateLimiter(requests_per_minute=60)
