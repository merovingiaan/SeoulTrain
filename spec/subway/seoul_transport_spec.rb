# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe 'Seoul subway transports' do
  context '/transports/:number URLs' do
    before :each do
      # visit root page for init mechanize agent (for better performance)
      visit '/'
    end

    it 'should be included first station name in line number 1 page' do
      visit '/transports/1'
      expect(page.body).to include('소요산')
    end
    
    it 'should be included first station name in line number 2 page' do
      visit '/transports/2'
      expect(page.body).to include('성수')
    end
    
    it 'should be included first station name in line number 3 page' do
      visit '/transports/3'
      expect(page.body).to include('대화')
    end
    
    it 'should be included first station name in line number 4 page' do
      visit '/transports/4'
      expect(page.body).to include('당고개')
    end
    
    it 'should be included first station name in line number 5 page' do
      visit '/transports/5'
      expect(page.body).to include('방화')
    end
    
    it 'should be included first station name in line number 6 page' do
      visit '/transports/6'
      expect(page.body).to include('응암')
    end
    
    it 'should be included first station name in line number 7 page' do
      visit '/transports/7'
      expect(page.body).to include('장암')
    end
    
    it 'should be included first station name in line number 8 page' do
      visit '/transports/8'
      expect(page.body).to include('암사')
    end

    it 'should be included first station name in line number 9 page' do
      visit '/transports/9'
      expect(page.body).to include('개화')
    end
  end
end