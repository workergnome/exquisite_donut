// Essentially works as an ArrayList but doesn't immediately remove an index.
// Instead the user has to call clearRemoved to actually remove all the indexes
// marked for removal using removeSafe, usually in some sort of update loop;

class SprinkleManager extends ArrayList<Sprinkle>{
    IntList sprinklesToRemove;
    
    SprinkleManager(){
        sprinklesToRemove = new IntList();
    }
    
    //  Special removal that doesn't actually delete from the list
    //  until clearRemoved() is called.    
    public Sprinkle removeSafe(int idx){
         sprinklesToRemove.appendUnique(idx);
         return this.get(idx);
    }
    // Overload of previous function to allow object-wise deletion
    public Sprinkle removeSafe(Sprinkle p){
         int idx = this.indexOf(p);
         if(idx == -1){
             return null;
         }
         sprinklesToRemove.appendUnique(idx);
         return p;
    }
    
    // Function to remove indices marked for deletion
    void clearRemoved(){
        // Sort descending to not screw up our indexing
        sprinklesToRemove.sortReverse();
        // Remove and publish sprinkles set for deletion
        while(sprinklesToRemove.size()>0){
            int idx = sprinklesToRemove.get(0);
            super.remove(idx);
            sprinklesToRemove.remove(0);
        }
    }
    
    // Clear should also clear removal buffer
    @Override
    public void clear(){
        super.clear();
        sprinklesToRemove.clear();
    }
    // Non-safe removal should also remove from the removal buffer
    @Override
    public Sprinkle remove(int idx){
         Sprinkle result = super.remove(idx);
         sprinklesToRemove.removeValue(idx);
         return result;
    }
    @Override
    public boolean remove(Object o){
        int idx = this.indexOf(o);
        if(idx != -1) sprinklesToRemove.removeValue(idx);
        return super.remove(o);
    }
}