/**
 * GaiaForge Website JavaScript
 * Professional implementation with smooth interactions and mobile optimization
 */

// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
  // Initialize all interactive components
  initMobileMenu();
  initDropdownMenus();
  initHeaderScroll();
  initScrollReveal();
  initTiltCards();
  initBackToTop();
  initSmoothScroll();
  initGalleryInteractions();
  initParallaxEffect();
});

/**
 * Mobile Menu Handler
 * Controls the main navigation menu on mobile devices
 */
function initMobileMenu() {
  const menuToggle = document.querySelector('.menu-toggle');
  const navMenu = document.querySelector('.nav-menu');
  
  if (menuToggle && navMenu) {
    menuToggle.addEventListener('click', function(e) {
      e.preventDefault();
      this.classList.toggle('active');
      navMenu.classList.toggle('active');
      document.body.classList.toggle('menu-open');
    });
    
    // Close menu when clicking outside
    document.addEventListener('click', function(e) {
      // Only if the menu is open and click is outside menu and toggle
      if (navMenu.classList.contains('active') && 
          !navMenu.contains(e.target) && 
          !menuToggle.contains(e.target)) {
        navMenu.classList.remove('active');
        menuToggle.classList.remove('active');
        document.body.classList.remove('menu-open');
      }
    });
  }
}

/**
 * Dropdown Menu Handler
 * Fixes the Products dropdown on mobile devices
 */
function initDropdownMenus() {
  const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
  
  if (dropdownToggles.length) {
    dropdownToggles.forEach(function(toggle) {
      toggle.addEventListener('click', function(e) {
        // Only prevent default behavior on mobile
        if (window.innerWidth <= 992) {
          e.preventDefault();
          
          // Find the dropdown menu - direct sibling
          const dropdownMenu = this.nextElementSibling;
          
          if (dropdownMenu && dropdownMenu.classList.contains('dropdown-menu')) {
            // Toggle active class
            dropdownMenu.classList.toggle('active');
            this.classList.toggle('active');
            
            // Close other dropdowns
            dropdownToggles.forEach(function(otherToggle) {
              if (otherToggle !== toggle) {
                const otherMenu = otherToggle.nextElementSibling;
                if (otherMenu && otherMenu.classList.contains('dropdown-menu')) {
                  otherMenu.classList.remove('active');
                  otherToggle.classList.remove('active');
                }
              }
            });
          }
        }
      });
    });
    
    // Handle clicks outside of dropdown
    document.addEventListener('click', function(e) {
      if (window.innerWidth <= 992) {
        // If click isn't on a dropdown-toggle or within a dropdown-menu
        if (!e.target.closest('.dropdown-toggle') && !e.target.closest('.dropdown-menu')) {
          // Close all dropdown menus
          document.querySelectorAll('.dropdown-menu').forEach(menu => {
            menu.classList.remove('active');
          });
          
          // Remove active state from toggles
          document.querySelectorAll('.dropdown-toggle').forEach(toggle => {
            toggle.classList.remove('active');
          });
        }
      }
    });
  }
}

/**
 * Header Scroll Effect
 * Changes header appearance when page is scrolled
 */
function initHeaderScroll() {
  const header = document.querySelector('.site-header');
  
  if (header) {
    // Apply class immediately if page is loaded scrolled down
    if (window.scrollY > 50) {
      header.classList.add('header-scrolled');
    }
    
    window.addEventListener('scroll', function() {
      if (window.scrollY > 50) {
        header.classList.add('header-scrolled');
      } else {
        header.classList.remove('header-scrolled');
      }
    });
  }
}

/**
 * Scroll-triggered animations with Intersection Observer
 * Animates sections as they enter the viewport
 */
function initScrollReveal() {
  const animatedElements = document.querySelectorAll('.reveal-section, .staggered-grid');
  
  if (animatedElements.length > 0) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('active');
          // Once animation is triggered, no need to observe anymore
          observer.unobserve(entry.target);
        }
      });
    }, {
      threshold: 0.15,
      rootMargin: '0px 0px -50px 0px'
    });
    
    // Observe all elements
    animatedElements.forEach(element => {
      observer.observe(element);
    });
  }
}

/**
 * Parallax Effect for Background Sections
 * Adds subtle movement to background images while scrolling
 */
function initParallaxEffect() {
  const parallaxSections = document.querySelectorAll('.parallax-section');
  
  if (parallaxSections.length > 0) {
    // Function to update parallax positions
    function updateParallax() {
      parallaxSections.forEach(section => {
        // Calculate if section is in viewport
        const rect = section.getBoundingClientRect();
        const isInViewport = (
          rect.top < window.innerHeight &&
          rect.bottom > 0
        );
        
        if (isInViewport) {
          const parallaxBg = section.querySelector('.parallax-bg');
          if (parallaxBg) {
            // Calculate how far the section is from the top of the viewport
            const viewportOffset = rect.top;
            const scrollPercent = viewportOffset / window.innerHeight;
            
            // Apply transform with subtle movement
            parallaxBg.style.transform = `translateY(${scrollPercent * 50}px)`;
          }
        }
      });
    }
    
    // Update on scroll
    window.addEventListener('scroll', updateParallax);
    
    // Initial update
    updateParallax();
  }
}

/**
 * 3D Tilt Effect for Cards
 * Creates an interactive tilt effect for product cards
 */
function initTiltCards() {
  const tiltCards = document.querySelectorAll('.tilt-card');
  
  if (tiltCards.length > 0) {
    tiltCards.forEach(card => {
      // Only enable tilt on devices that support hover
      if (window.matchMedia('(hover: hover)').matches) {
        const inner = card.querySelector('.tilt-card-inner');
        
        if (inner) {
          card.addEventListener('mousemove', e => {
            // Get card dimensions and mouse position
            const rect = card.getBoundingClientRect();
            const mouseX = e.clientX - rect.left;
            const mouseY = e.clientY - rect.top;
            
            // Calculate rotation based on mouse position
            // We make the effect more subtle for a professional look
            const rotateX = ((mouseY - rect.height / 2) / rect.height) * 5;
            const rotateY = -((mouseX - rect.width / 2) / rect.width) * 5;
            
            // Apply transform with perspective
            inner.style.transform = `rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
          });
          
          // Reset on mouse leave
          card.addEventListener('mouseleave', () => {
            inner.style.transform = 'rotateX(0) rotateY(0)';
          });
        }
      }
    });
  }
}

/**
 * Back to Top Button
 * Shows/hides button and scrolls to top when clicked
 */
function initBackToTop() {
  const backToTopBtn = document.querySelector('.back-to-top');
  
  if (backToTopBtn) {
    // Show/hide button based on scroll position
    window.addEventListener('scroll', () => {
      if (window.pageYOffset > 300) {
        backToTopBtn.classList.add('visible');
      } else {
        backToTopBtn.classList.remove('visible');
      }
    });
    
    // Scroll to top on click
    backToTopBtn.addEventListener('click', e => {
      e.preventDefault();
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
  }
}

/**
 * Smooth Scroll for Anchor Links
 * Adds smooth scrolling behavior to all anchor links
 */
function initSmoothScroll() {
  // Select all anchor links except back-to-top
  const anchorLinks = document.querySelectorAll('a[href^="#"]:not([href="#"]):not(.back-to-top)');
  
  anchorLinks.forEach(link => {
    link.addEventListener('click', e => {
      const targetId = link.getAttribute('href');
      const targetElement = document.querySelector(targetId);
      
      if (targetElement) {
        e.preventDefault();
        
        // Calculate position with offset for fixed header
        const headerHeight = document.querySelector('.site-header')?.offsetHeight || 0;
        const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - headerHeight;
        
        // Smooth scroll to target
        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });
        
        // Update URL hash without scrolling
        history.pushState(null, null, targetId);
      }
    });
  });
}

/**
 * Interactive Gallery
 * Adds hover effects and optional lightbox functionality
 */
function initGalleryInteractions() {
  const galleryItems = document.querySelectorAll('.gallery-item');
  
  if (galleryItems.length > 0) {
    galleryItems.forEach(item => {
      // Optional: Enable lightbox on gallery click
      item.addEventListener('click', function() {
        if (window.enableLightbox) { // Only if explicitly enabled
          const imgSrc = this.querySelector('img').getAttribute('src');
          const title = this.querySelector('h3')?.textContent || '';
          
          openGalleryModal(imgSrc, title);
        }
      });
    });
  }
}

/**
 * Gallery Lightbox Modal
 * Creates a lightbox effect for gallery images when clicked
 */
function openGalleryModal(imgSrc, title) {
  // Create modal elements
  const modal = document.createElement('div');
  modal.classList.add('gallery-modal');
  
  const modalContent = document.createElement('div');
  modalContent.classList.add('gallery-modal-content');
  
  const closeBtn = document.createElement('button');
  closeBtn.classList.add('gallery-modal-close');
  closeBtn.innerHTML = '&times;';
  
  const modalImage = document.createElement('img');
  modalImage.src = imgSrc;
  modalImage.alt = title;
  
  const modalTitle = document.createElement('h3');
  modalTitle.textContent = title;
  
  // Assemble modal
  modalContent.appendChild(closeBtn);
  modalContent.appendChild(modalImage);
  modalContent.appendChild(modalTitle);
  modal.appendChild(modalContent);
  
  // Add to body
  document.body.appendChild(modal);
  
  // Prevent body scrolling
  document.body.style.overflow = 'hidden';
  
  // Add animation class after small delay for transition effect
  setTimeout(() => {
    modal.classList.add('active');
  }, 10);
  
  // Close modal on click
  closeBtn.addEventListener('click', () => {
    closeGalleryModal(modal);
  });
  
  // Also close when clicking outside content
  modal.addEventListener('click', e => {
    if (e.target === modal) {
      closeGalleryModal(modal);
    }
  });
  
  // Close on ESC key
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
      closeGalleryModal(modal);
    }
  });
}

/**
 * Close Gallery Modal
 */
function closeGalleryModal(modal) {
  modal.classList.remove('active');
  
  // Remove modal after animation completes
  setTimeout(() => {
    document.body.removeChild(modal);
    document.body.style.overflow = '';
  }, 300);
}

/**
 * Enables elements with subtle hover animations 
 * This adds a subtle interaction effect across the site
 */
window.addEventListener('DOMContentLoaded', function() {
  // Add subtle hover effect to buttons
  const buttons = document.querySelectorAll('.btn');
  buttons.forEach(btn => {
    btn.addEventListener('mouseenter', function() {
      this.style.transform = 'translateY(-2px)';
      this.style.boxShadow = '0 5px 15px rgba(0, 0, 0, 0.1)';
    });
    
    btn.addEventListener('mouseleave', function() {
      this.style.transform = '';
      this.style.boxShadow = '';
    });
  });
  
  // Add focus state improvements for accessibility
  const focusableElements = document.querySelectorAll('a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])');
  focusableElements.forEach(el => {
    el.addEventListener('focus', function() {
      this.classList.add('focus-visible');
    });
    
    el.addEventListener('blur', function() {
      this.classList.remove('focus-visible');
    });
  });
});

/**
 * Browser Feature Detection
 * Adds helper classes to the body based on browser capabilities
 */
(function() {
  // Touch device detection
  if ('ontouchstart' in window || navigator.maxTouchPoints > 0) {
    document.body.classList.add('touch-device');
  } else {
    document.body.classList.add('no-touch');
  }
  
  // Add reduced-motion class for accessibility
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    document.body.classList.add('reduced-motion');
  }
})();